import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CustomerVehiclesView: View {
    @State private var vehicles: [Vehicle] = [] // Stores vehicles
    @State private var showingAddVehicleSheet = false // Toggles Add Vehicle sheet
    @State private var alertItem: AlertItem? // For error handling

    var body: some View {
        NavigationView {
            VStack {
                if vehicles.isEmpty {
                    Text("No vehicles added yet.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(vehicles) { vehicle in
                        VStack(alignment: .leading) {
                            Text(vehicle.name)
                                .font(.headline)
                            Text("License Plate: \(vehicle.licensePlate)")
                                .font(.subheadline)
                            Text("Type: \(vehicle.type)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Add Vehicle button
                Button(action: {
                    showingAddVehicleSheet.toggle()
                }) {
                    Text("Add Vehicle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("My Vehicles")
            .sheet(isPresented: $showingAddVehicleSheet) {
                AddCustomerVehicleView(onSave: { newVehicle in
                    addVehicle(newVehicle)
                })
            }
            .onAppear {
                fetchCustomerVehicles()
            }
            .alert(item: $alertItem) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchCustomerVehicles() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertItem = AlertItem(title: "Authentication Error", message: "User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).collection("vehicles").getDocuments { snapshot, error in
            if let error = error {
                alertItem = AlertItem(title: "Error", message: "Error fetching vehicles: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot {
                vehicles = snapshot.documents.compactMap { document in
                    let data = document.data()
                    return Vehicle(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        licensePlate: data["licensePlate"] as? String ?? "",
                        type: data["type"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func addVehicle(_ vehicle: Vehicle) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertItem = AlertItem(title: "Authentication Error", message: "User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        do {
            try db.collection("users").document(userUID).collection("vehicles").addDocument(from: vehicle)
            vehicles.append(vehicle)
        } catch {
            alertItem = AlertItem(title: "Error", message: "Error saving vehicle: \(error.localizedDescription)")
        }
    }
}

struct AddCustomerVehicleView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Vehicle) -> Void

    @State private var name: String = ""
    @State private var licensePlate: String = ""
    @State private var type: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Vehicle Name", text: $name)
                TextField("License Plate", text: $licensePlate)
                TextField("Type (e.g., Sedan, SUV)", text: $type)
            }
            .navigationTitle("Add Vehicle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newVehicle = Vehicle(
                            name: name,
                            licensePlate: licensePlate,
                            type: type
                        )
                        onSave(newVehicle)
                        dismiss()
                    }
                    .disabled(name.isEmpty || licensePlate.isEmpty || type.isEmpty)
                }
            }
        }
    }
}
