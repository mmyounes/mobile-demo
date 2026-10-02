import SwiftUI
// Default skywards information to use as fallback
private let defaultSharedMessage = SharedMessageContent(
    message: "Welcome to the app!",
    color: "green",
    size: 18
)
// MARK: - Combined Water View (Field Agent & Customer Details)
struct WaterView: View {
    // The username/ID of the customer, passed from the login screen.
    let username: String
    
    @StateObject private var dbManager = DatabaseManager.shared
    
    // State for managing the UI
    @State private var isEditingPhoneNumber = false
    @State private var editingPhoneNumber = ""
    @State private var userNote: String = ""
    @State private var newReading: String = ""

    // A formatter for displaying dates.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    // Fallback data to prevent crashes if data hasn't loaded yet.
    private var defaultWaterInfo: WaterCustomerInfo {
        WaterCustomerInfo(
            customerName: "Loading...",
            contractNumber: "CUST-000000",
            tier: "N/A",
            usageStatus: "N/A",
            currentReadingM3: 0.0,
            lastReadingDate: Date(),
            phoneNumber: "000-000-0000",
            note: ""
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Use the fetched customer info or the default as a fallback.
                let customerInfo = dbManager.waterCustomerInfo ?? defaultWaterInfo
                
                // --- HEADER ---
                HStack(spacing: 15) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Hi \(customerInfo.customerName)!")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "drop.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 20)
                                .padding(.horizontal)
                                
                // Shared Message - uses either retrieved data or default
                let sharedMessage = dbManager.sharedMessage ?? defaultSharedMessage
                
                
                // --- Shared Msg ---
                HStack(spacing: 15) {
                                        Image(systemName: "megaphone")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    
                            Text(sharedMessage.message)
                                .font(.custom("Poppins-Bold", size: CGFloat(sharedMessage.size)))
                                .foregroundColor(Color.from(name: sharedMessage.color))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 20)
                                .padding(.leading, 20)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "wrench.adjustable.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 20)
                                .padding(.horizontal)

                
                // --- CURRENT READING & NEW READING INPUT ---
                VStack(spacing: 20) {
                    Text("Current Reading")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(customerInfo.currentReadingM3, specifier: "%.2f") m³")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Last reading on \(dateFormatter.string(from: customerInfo.lastReadingDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter New Reading (m³)", text: $newReading)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: submitNewReading) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Submit New Reading")
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newReading.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(newReading.isEmpty)
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // --- CUSTOMER INFO & CONTACT CARD ---
                VStack(spacing: 15) {
                    Text("Customer Account Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contract Number").font(.subheadline).foregroundColor(.gray)
                            Text(customerInfo.contractNumber).font(.title3).fontWeight(.medium)
                        }
                        Spacer()
                        Text(customerInfo.tier).font(.title3).fontWeight(.bold).foregroundColor(.green)
                            .padding(.horizontal, 15).padding(.vertical, 5)
                            .background(Color.green.opacity(0.1)).cornerRadius(5)
                    }
                    
                    Divider()
                    
                    // Editable Phone Number Section
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number").font(.subheadline).foregroundColor(.gray)
                            if isEditingPhoneNumber {
                                TextField("Enter phone number", text: $editingPhoneNumber)
                                    .font(.title3).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                            } else {
                                Text(customerInfo.phoneNumber ?? "Not Set")
                                    .font(.title3).fontWeight(.medium)
                            }
                        }
                        Spacer()
                        if isEditingPhoneNumber {
                            HStack {
                                Button("Apply") {
                                     dbManager.updatePhoneNumber(for: username, newNumber: editingPhoneNumber)
                                    isEditingPhoneNumber = false
                                }.fontWeight(.bold)
                                Button("Cancel") { isEditingPhoneNumber = false }.foregroundColor(.red)
                            }
                        } else {
                            Button("Edit") {
                                editingPhoneNumber = customerInfo.phoneNumber ?? ""
                                isEditingPhoneNumber = true
                            }.buttonStyle(PlainButtonStyle()).padding(8)
                             .background(Color.blue.opacity(0.1)).clipShape(Circle())
                        }
                    }.animation(.default, value: isEditingPhoneNumber)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // --- EDITABLE NOTES SECTION ---
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes").font(.headline)
                    HStack(spacing: 12) {
                        TextField("Add a note for this customer...", text: $userNote, axis: .vertical)
                            .padding(10).background(Color(.systemGray6)).cornerRadius(8).lineLimit(1...5)
                        Button(action: {
                             dbManager.updateNote(for: username, newNote: userNote)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "square.and.arrow.down.fill").font(.title2)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Text("Sync status: \(dbManager.syncStatus)")
                    .font(.subheadline).foregroundColor(.gray).padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationTitle("Customer Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dbManager.getWaterCustomerInfo(forCustomerID: username)
            dbManager.getSharedMessage()
            self.userNote = dbManager.waterCustomerInfo?.note ?? ""
        }
        .onChange(of: dbManager.waterCustomerInfo) { newInfo in
            self.userNote = newInfo?.note ?? ""
        }
    }
    
    private func submitNewReading() {
        guard let newUsageValue = Double(newReading) else {
            print("Invalid number format")
            return
        }
        
        print("Submitting new reading: \(newUsageValue) for customer \(username)")
        
        // Here you would call your database manager to save the new value.
        dbManager.updateWaterReading(for: username, newWaterUsage: newUsageValue)
        
        // For demonstration, we update the local state.
//        dbManager.waterCustomerInfo?.currentReadingM3 = newUsageValue
        newReading = "" // Clear the text field
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
