import SwiftUI

struct DriverVehiclesView: View {
    @State private var vehicles: [Vehicle] = [] // A list to store the driver's vehicles
    @State private var showingAddVehicleSheet = false // Controls the Add Vehicle sheet

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
            .navigationTitle("My Towing Vehicles")
            .sheet(isPresented: $showingAddVehicleSheet) {
                AddDriverVehicleView(vehicles: $vehicles)
            }
        }
    }
}

struct AddDriverVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var vehicles: [Vehicle]
    
    @State private var name: String = ""
    @State private var licensePlate: String = ""
    @State private var type: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Vehicle Name", text: $name)
                TextField("License Plate", text: $licensePlate)
                TextField("Type (e.g., Flatbed, Hook)", text: $type)
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
                        let newVehicle = Vehicle(name: name, licensePlate: licensePlate, type: type)
                        vehicles.append(newVehicle)
                        dismiss()
                    }
                    .disabled(name.isEmpty || licensePlate.isEmpty || type.isEmpty)
                }
            }
        }
    }
}
