//
//  WelcomeView.swift
//  emiratespoc
//
//  Created by Mahmoud Younes on 16/03/2025.
//

import SwiftUI


// MARK: - color name
extension Color {
    static func from(name: String) -> Color? {
        let colorMap: [String: Color] = [
            "red": .red,
            "blue": .blue,
            "green": .green,
            "yellow": .yellow,
            "orange": .orange,
            "purple": .purple,
            "black": .black,
            "white": .white,
            "gray": .gray,
            "cyan": .cyan,
        ]
        return colorMap[name.lowercased()]
    }
}

// MARK: - Skywards Member Info
struct SkywardsMemberInfo {
    let membershipNumber: String
    let tierStatus: String
    let miles: Int
    let tierMiles: Int
}

// MARK: - Shared message content
struct SharedMessageContent {
    let message: String
    let color: String
    let size: Int
}

// MARK: - Trip Details
struct Trip {
    let departureCity: String
    let destinationCity: String
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let airline: String
    let flightNumber: String
}


// MARK: - Welcome View
struct WelcomeView: View {
    let username: String
    @StateObject private var dbManager = DatabaseManager.shared
    
    // Default skywards information to use as fallback
    private let defaultSkywardsInfo = SkywardsMemberInfo(
        membershipNumber: "EK-000000000",
        tierStatus: "Blue",
        miles: 0,
        tierMiles: 0
    )
    
    // Default skywards information to use as fallback
    private let defaultSharedMessage = SharedMessageContent(
        message: "Welcome to the app!",
        color: "green",
        size: 18
    )
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Hi \(username)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            
            // Shared Message - uses either retrieved data or default
            let sharedMessage = dbManager.sharedMessage ?? defaultSharedMessage
            
            Text(sharedMessage.message)
                .font(.custom("Poppins-Bold", size: CGFloat(sharedMessage.size)))
                .foregroundColor(Color.from(name: sharedMessage.color))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.leading, 20)
            
            
            // Skywards information card - uses either retrieved data or default
            let skywardsInfo = dbManager.skywardsInfo ?? defaultSkywardsInfo
            
            // Skywards information card
            VStack(spacing: 15) {
                Text("Skywards Membership")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Membership Number")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(skywardsInfo.membershipNumber)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text(skywardsInfo.tierStatus)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skywards Miles")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(skywardsInfo.miles)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Tier Miles")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(skywardsInfo.tierMiles)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            
            
            // MARK: - Trip Card View
            
            let trip = dbManager.trip ?? Trip(departureCity: "Dubai", destinationCity: "Riyadh", departureTime: "11:00", arrivalTime: "13:00", duration: "2h", airline: "Emirates", flightNumber: "EK 203")
            VStack(alignment: .leading, spacing: 12) {
                // Flight Route
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.departureCity)
                            .font(.headline)
                        Text(trip.departureTime)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "airplane")
                        .foregroundColor(.blue)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(trip.destinationCity)
                            .font(.headline)
                        Text(trip.arrivalTime)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Duration
                Text("Duration: \(trip.duration)")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Airline and Flight Number
                HStack {
                    Text(trip.airline)
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("Flight \(trip.flightNumber)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Text("Sync status: \(dbManager.syncStatus)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 20)
            
            Spacer()
            
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set up live query when view appears
            print("before query: \(dbManager.skywardsInfo)")
            dbManager.getSkywardsInfo(forUsername: username)
            dbManager.getSharedMessage()
        }
        .onDisappear {
            // Stop sync when navigating away
            //dbManager.stopSync()
        }
    }
}

