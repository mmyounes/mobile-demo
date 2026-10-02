//
//  DatabaseManager.swift
//  emiratespoc
//
//  Created by Mahmoud Younes on 16/03/2025.
//


import CouchbaseLiteSwift

// MARK: - Sync Gateway Settings
// Replace these placeholders with your own environment (see README.md, "Configure the app").
enum SyncSettings {
    // Public replication endpoint of your Sync Gateway database: ws://<host>:4984/<db>
    // Use wss:// when Sync Gateway is configured with TLS.
    static let endpoint = "ws://YOUR_SGW_HOST:4984/mydb"
    // Sync Gateway user created with the Admin API (POST /mydb/_user/)
    static let username = "YOUR_SGW_USERNAME"
    static let password = "YOUR_SGW_PASSWORD"
}

// MARK: - Database Manager
class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    
    var usersColl:Collection? {
        get {
            return usersCollection
        }
    }
    
    private var usersCollection: Collection?
    private var sharedCollection: Collection?
    //private var knowledgeBaseCollection: Collection?
    private var database: Database?
    private var replicator: Replicator?
    @Published var syncStatus: String = "Not synced"
    
    private var liveQuery: Query?
    private var queryToken: ListenerToken?
    
    @Published var skywardsInfo: SkywardsMemberInfo?
    @Published var sharedMessage: SharedMessageContent?
    @Published var trip: Trip?
    @Published var waterCustomerInfo: WaterCustomerInfo?

    init() {
        setupDatabase()
       
    }
    
    private func setupDatabase() {
        do {
            // Enable Vector Search Extension
            try Extension.enableVectorSearch()
            
            
            // Create or open the database
            database = try Database(name: "mydb")
            usersCollection = try database?.createCollection(name: "users", scope: "mainscope")
            sharedCollection = try database?.createCollection(name: "shared", scope: "mainscope")
//            var localCollection = try database?.createCollection(name: "knowledgeBase", scope: "mainscope")
            
            // create a collection dedicated for RAG workflow (local in device)
            //knowledgeBaseCollection = try database?.createCollection(name: "knowledgeBase")
            
            // Sync with server
            syncWithServer(username: SyncSettings.username, password: SyncSettings.password)
            print("Database created/opened successfully")
        } catch {
            print("Error creating/opening database: \(error)")
        }
    }
    
    private func syncWithServer(username: String, password: String) {
        guard let database = database else { return }
        guard let usersCollection = usersCollection else { return }
        guard let sharedCollection = sharedCollection else { return }
        
        
        // Create replicator configuration
        let targetEndpoint = URLEndpoint(url: URL(string: SyncSettings.endpoint)!)
        
        // Create Collection configuration.
        let UserColConfig = CollectionConfiguration(collection: usersCollection)
        let SharedColConfig = CollectionConfiguration(collection: sharedCollection)
        
        // Create replicator configuration with the target endpoint and collection configuration.
        var config = ReplicatorConfiguration(collections: [UserColConfig, SharedColConfig], target: targetEndpoint)
        
        // Set up basic authentication
        config.authenticator = BasicAuthenticator(username: username, password: password)
        
        // Configure replication type (push, pull, or both)
        config.replicatorType = .pushAndPull
        
        // Configure continuous replication
        config.continuous = true
        
        // Create replicator
        replicator = Replicator(config: config)
        
        // Add change listener
        replicator?.addChangeListener { [weak self] change in
            guard let self = self else { return }
            print (change)
            if let error = change.status.error {
                DispatchQueue.main.async {
                    self.syncStatus = "Error: \(error.localizedDescription)"
                }
                print("Sync error: \(error)")
            } else {
                let progress = change.status.progress
                DispatchQueue.main.async {
                    self.syncStatus = "Syncing: \(progress.completed)/\(progress.total)"
                    
                    if change.status.activity == .idle {
                        self.syncStatus = "Sync complete"
                    }
                }
            }
        }
        
        // Start replication
        replicator?.start()
    }
    
    
    func getSkywardsInfo(forUsername username: String) {
        guard let usersCollection = usersCollection else { return }
        
        // Cancel any existing query listener
        if let token = queryToken {
            token.remove()
            queryToken = nil
        }
        
        do {
            // Create a query for the specific user document
            let query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(usersCollection))
                .where(Expression.property("_id").equalTo(Expression.string(username)))
            
            
            _ = query.addChangeListener { (change) in
                for result in change.results! {
                    if let doc = result.dictionary(forKey: "users") {
                        let membershipNumber = doc.string(forKey: "membershipNumber") ?? "Unknown"
                        let tierStatus = doc.string(forKey: "tierStatus") ?? "Blue"
                        let miles = doc.int(forKey: "miles")
                        let tierMiles = doc.int(forKey: "tierMiles")
                        let departureCity = doc.string(forKey: "departureCity") ?? "Unknown"
                        let destinationCity = doc.string(forKey: "destinationCity") ?? "Unknown"
                        let departureTime = doc.string(forKey: "departureTime") ?? "Unknown"
                        let arrivalTime = doc.string(forKey: "arrivalTime") ?? "Unknown"
                        let duration = doc.string(forKey: "duration") ?? "Unknown"
                        let airline = doc.string(forKey: "airline") ?? "Unknown"
                        let flightNumber = doc.string(forKey: "flightNumber") ?? "Unknown"
                        let phoneNumber = doc.string(forKey: "phoneNumber") ?? "Unknown"
                        let note = doc.string(forKey: "note") ?? ""


                        print("result value: \(result.toDictionary())")
                        print("miles value: \(miles)")
                        // Create new SkywardsMemberInfo object
                        let newInfo = SkywardsMemberInfo(
                            membershipNumber: membershipNumber,
                            tierStatus: tierStatus,
                            miles: Int(miles),
                            tierMiles: Int(tierMiles),
                            phoneNumber: phoneNumber,
                            note: note
                        )
                        
                        //Create a new Trip
                        let newTrip = Trip(
                            departureCity: departureCity,
                            destinationCity: destinationCity,
                            departureTime: departureTime,
                            arrivalTime: arrivalTime,
                            duration: duration,
                            airline: airline,
                            flightNumber: flightNumber
                        )
                        
                        print("successful query: \(newInfo)")
                        DispatchQueue.main.async {
                            self.skywardsInfo = newInfo
                            self.trip = newTrip
                        }
                    }
                }
            }
        }
        catch {
            print("Error setting up live query: \(error)")
        }
        
    }
    
   
    func getWaterCustomerInfo(forCustomerID customerID: String) {
        // 1. Use the 'users' collection as requested.
        guard let usersCollection = self.usersCollection else {
            print("Error: Users collection is not available.")
            return
        }
        
        // Cancel any existing query listener to avoid duplicates.
        if let token = queryToken {
            token.remove()
            queryToken = nil
        }
        
        // A formatter to handle ISO 8601 date strings from JSON.
        let dateFormatter = ISO8601DateFormatter()
        
        do {
            // 2. Build the query against the 'users' collection.
            let query = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.collection(usersCollection))
                .where(Expression.property("_id").equalTo(Expression.string(customerID)))
            
            // 3. Use only ONE change listener.
            let token = query.addChangeListener { [weak self] (change) in
                guard let self = self else { return }
                
                // Check for the first result.
                if let result = change.results?.allResults().first,
                   // 4. Use the correct key, which is now 'users'.
                   let doc = result.dictionary(forKey: "users") {
                    
                    // Safely extract all properties from the document.
                    let customerName = doc.string(forKey: "customerName") ?? "N/A"
                    let contractNumber = doc.string(forKey: "contractNumber") ?? "N/A"
                    let tier = doc.string(forKey: "tier") ?? "Unknown"
                    let usageStatus = doc.string(forKey: "usageStatus") ?? "Unknown"
                    let currentReadingM3 = doc.double(forKey: "currentReadingM3")
                    let phoneNumber = doc.string(forKey: "phoneNumber") ?? "Unknown"
                    let note = doc.string(forKey: "note") ?? ""
                    
                    // Parse the date string into a Date object.
                    let dateString = doc.string(forKey: "lastReadingDate") ?? ""
                    let lastReadingDate = dateFormatter.date(from: dateString) ?? Date()
                    
                    // Create a new WaterCustomerInfo object.
                    let newInfo = MobileDemo.WaterCustomerInfo(
                        customerName: customerName,
                        contractNumber: contractNumber,
                        tier: tier,
                        usageStatus: usageStatus,
                        currentReadingM3: currentReadingM3,
                        lastReadingDate: lastReadingDate,
                        phoneNumber: phoneNumber,
                        note: note
                    )
                    
                    // Update the @Published property on the main thread.
                    // 5. Ensure the property name uses standard Swift camelCase.
                    DispatchQueue.main.async {
                        self.waterCustomerInfo = newInfo
                    }
                }
            }
            
            // Store the listener token so it can be removed later.
            self.queryToken = token
            
        } catch {
            print("Error setting up live query for water customer: \(error)")
        }
    }
    func updatePhoneNumber(for username: String, newNumber: String) {
        // 1. Ensure the database object is available
        guard let usersCollection = usersCollection else { return }
        
        
        do {
            // 2. Get the specific collection named "users"
            // 3. Fetch the document from that collection using its ID
            if let document = try usersCollection.document(id: username) {
                
                // 4. Create a mutable copy to allow changes
                let mutableDocument = document.toMutable()
                
                // 5. Set the new value for the "phoneNumber" field
                mutableDocument.setString(newNumber, forKey: "phoneNumber")
                
                // 6. Save the updated document back to the "users" collection
                try usersCollection.save(document: mutableDocument)
                
                print("Successfully updated phone number for '\(username)' in 'users' collection.")
                
                // 7. Update the UI instantly by modifying the published property
                DispatchQueue.main.async {
                    self.skywardsInfo?.phoneNumber = newNumber
                }
                
            } else {
                print("Error: Document for username '\(username)' not found in 'users' collection.")
            }
        } catch {
            print("Error updating document in Couchbase Lite: \(error.localizedDescription)")
        }
    }
    
    func updateNote(for username: String, newNote: String) {
        guard let usersCollection = usersCollection else { return }
        
 
        do {
            if let document = try usersCollection.document(id: username) {
                let mutableDocument = document.toMutable()
                mutableDocument.setString(newNote, forKey: "note")
                try usersCollection.save(document: mutableDocument)
                print("Successfully updated note for '\(username)'.")
                DispatchQueue.main.async {
                    self.skywardsInfo?.note = newNote
                }
            }
        } catch {
            print("Error updating note in Couchbase Lite: \(error.localizedDescription)")
        }
    }
    
    func updateWaterReading(for username: String, newWaterUsage: Double) {
        guard let usersCollection = usersCollection else { return }
        
 
        do {
            if let document = try usersCollection.document(id: username) {
                let mutableDocument = document.toMutable()
                mutableDocument.setDouble(newWaterUsage, forKey: "currentReadingM3")
                try usersCollection.save(document: mutableDocument)
                print("Successfully updated water usage for '\(username)'.")
                DispatchQueue.main.async {
                    self.waterCustomerInfo?.currentReadingM3 = newWaterUsage
                    
                }
            }
        } catch {
            print("Error updating note in Couchbase Lite: \(error.localizedDescription)")
        }
    }
    
    func getSharedMessage() {
        do {
            let query = try database?.createQuery("SELECT * FROM mainscope.shared WHERE META().id = 'content'")
            
            _ = query?.addChangeListener { (change) in
                for result in change.results! {
                    if let doc = result.dictionary(forKey: "shared") {
                        let message = doc.string(forKey: "message") ?? "Unknown"
                        let color = doc.string(forKey: "color") ?? "Blue"
                        let size = doc.int(forKey: "size") ?? 24
                        
                        print("result value: \(result.toDictionary())")
                        print("message value: \(message)")
                        // Create new sharedMessage object
                        let newMessage = SharedMessageContent(
                            message: message,
                            color: color,
                            size: Int(size)
                        )
                        print("successful query: \(newMessage)")
                        DispatchQueue.main.async {
                            self.sharedMessage = newMessage
                        }
                    }
                }
            }
            
        } catch {
            print("Error setting up live query: \(error)")
        }
    }
}
