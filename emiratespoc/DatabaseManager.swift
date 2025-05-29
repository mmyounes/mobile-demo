//
//  DatabaseManager.swift
//  emiratespoc
//
//  Created by Mahmoud Younes on 16/03/2025.
//


import CouchbaseLiteSwift

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
    private var database: Database?
    private var replicator: Replicator?
    @Published var syncStatus: String = "Not synced"
    
    private var liveQuery: Query?
    private var queryToken: ListenerToken?
    
    @Published var skywardsInfo: SkywardsMemberInfo?
    @Published var sharedMessage: SharedMessageContent?
    @Published var trip: Trip?
    
    init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            // Create or open the database
            database = try Database(name: "mydb")
            usersCollection = try database?.createCollection(name: "users", scope: "mainscope")
            sharedCollection = try database?.createCollection(name: "shared", scope: "mainscope")
            sharedCollection = try database?.createCollection(name: "local", scope: "mainscope")
            syncWithServer(username: "user_name", password: "password")
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
        let targetEndpoint = URLEndpoint(url: URL(string: "wss://xxxxxxxxxxxxxxx.apps.cloud.couchbase.com:4984/endpoint")!)
        var config = ReplicatorConfiguration(target: targetEndpoint)
        
        // create the collection
        config.addCollection(usersCollection)
        config.addCollection(sharedCollection)
        
        
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
            
            
            let token = query.addChangeListener { (change) in
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
                        
                        print("result value: \(result.toDictionary())")
                        print("miles value: \(miles)")
                        // Create new SkywardsMemberInfo object
                        let newInfo = SkywardsMemberInfo(
                            membershipNumber: membershipNumber,
                            tierStatus: tierStatus,
                            miles: Int(miles),
                            tierMiles: Int(tierMiles)
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
    
    func getSharedMessage() {
        do {
            let query = try database?.createQuery("SELECT * FROM mainscope.shared WHERE META().id = 'content'")
            
            let token = query?.addChangeListener { (change) in
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
