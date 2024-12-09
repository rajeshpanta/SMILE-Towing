import SwiftUI

struct RoleSelectionView: View {
    @State private var selectedRole: String? = nil // State to track navigation
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
        }
    }
    private var content: some View {
            VStack(spacing: 30) {
                Text("Welcome to SMILE Towing!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                
                    Text("We Make Towing Easier")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
                
                Text("Choose to login as a")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                
                // Driver Button
                NavigationLink(destination: DriverSignInView(), tag: "Driver", selection: $selectedRole) {
                    Button(action: {
                        selectedRole = "Driver"
                    }) {
                        Text("Driver")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                
                
                // Customer Button
                NavigationLink(destination: CustomerSignInView(), tag: "Customer", selection: $selectedRole) {
                    Button(action: {
                        selectedRole = "Customer"
                    }) {
                        Text("Customer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
