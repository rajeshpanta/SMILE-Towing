import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AvailableJobView: View {
    @State private var availableJobs: [TowRequest] = [] // Holds the list of available jobs
    @State private var selectedJob: TowRequest? = nil // Tracks the selected job
    @State private var showJobDetails: Bool = false // Tracks navigation to job details

    var body: some View {
        NavigationView {
            VStack {
                if availableJobs.isEmpty {
                    ProgressView("Fetching jobs...")
                        .padding()
                } else {
                    List(availableJobs) { job in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Address: \(job.address)")
                                .font(.headline)
                            Text("Issue: \(job.issue)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .onTapGesture {
                            selectedJob = job
                            showJobDetails = true
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Available Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: fetchAvailableJobs)
            .sheet(isPresented: $showJobDetails) {
                if let selectedJob = selectedJob {
                    JobDetailsView(job: selectedJob) // Navigate to Job Details View
                }
            }
        }
    }
    
    // MARK: - Fetch Available Jobs from Firestore
    private func fetchAvailableJobs() {
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: Driver is not authenticated. Please log in.")
            return
        }
        
        let db = Firestore.firestore()
        print("Fetching jobs for Driver UID: \(currentUser.uid)")
        
        // Fetch driver details from the "users" collection
        db.collection("users").document(currentUser.uid).getDocument { (document, error) in
            if let error = error {
                print("Error fetching driver document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Error: Driver document does not exist in Firestore.")
                return
            }
            
            let data = document.data() ?? [:]
            print("Driver Firestore document data: \(data)")
            
            let role = data["role"] as? String ?? "No role found"
            print("Driver role fetched: \(role)")
            
            // Ensure the user is a driver
            if role != "Driver" {
                print("Error: User is not authorized to view jobs. Role: \(role)")
                return
            }
            
            print("Driver is authorized to view jobs.")
            
            // Fetch pending tow requests
            db.collection("tow_requests")
                .whereField("status", isEqualTo: "Pending")
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error fetching tow requests: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found in the 'tow_requests' collection.")
                        return
                    }
                    
                    print("Fetched \(documents.count) pending tow requests.")
                    
                    // Parse the documents into TowRequest objects
                    DispatchQueue.main.async {
                        self.availableJobs = documents.compactMap { document -> TowRequest? in
                            let data = document.data()
                            print("Processing job document ID: \(document.documentID)")
                            
                            guard let issue = data["issue"] as? String else {
                                print("Error: Missing or invalid 'issue' field in document ID: \(document.documentID).")
                                return nil
                            }
                            
                            guard let customerId = data["customer_id"] as? String else {
                                print("Error: Missing or invalid 'customer_id' field in document ID: \(document.documentID).")
                                return nil
                            }
                            
                            guard let location = data["location"] as? GeoPoint else {
                                print("Error: Missing or invalid 'location' field in document ID: \(document.documentID).")
                                return nil
                            }
                            
                            // Generate address from GeoPoint
                            let address = "Lat: \(location.latitude), Lon: \(location.longitude)"
                            
                            print("Parsed job document successfully. Issue: \(issue), Address: \(address), CustomerID: \(customerId)")
                            
                            return TowRequest(id: document.documentID, address: address, issue: issue, customerId: customerId)
                        }
                        
                        print("Available jobs updated. Total jobs: \(self.availableJobs.count)")
                    }
                }
        }
    }
    // MARK: - TowRequest Model
    struct TowRequest: Identifiable {
        let id: String
        let address: String
        let issue: String
        let customerId: String
    }
    
    // MARK: - JobDetailsView
    struct JobDetailsView: View {
        let job: TowRequest
        @Environment(\.presentationMode) var presentationMode // For dismissing the view
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Job Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Address:")
                            .font(.headline)
                        Spacer()
                        Text(job.address)
                            .font(.subheadline)
                    }
                    
//                    HStack {
//                        Text("Issue:")
//                            .font(.headline)
//                        Spacer()
//                        Text(job.issue)
//                            .font(.subheadline)
//                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(radius: 5)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        acceptJob()
                    }) {
                        Text("Accept")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        declineJob()
                    }) {
                        Text("Decline")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        
        // MARK: - Accept Job
        private func acceptJob() {
            let db = Firestore.firestore()
            guard let driverID = Auth.auth().currentUser?.uid else {
                print("Error: Driver is not authenticated.")
                return
            }
            
            db.collection("tow_requests").document(job.id).updateData([
                "status": "Accepted",
                "driver_id": driverID // Use the authenticated driver's ID
            ]) { error in
                if let error = error {
                    print("Error accepting job: \(error.localizedDescription)")
                } else {
                    print("Job accepted successfully!")
                    presentationMode.wrappedValue.dismiss() // Dismiss the job details view
                }
            }
        }
        
        // MARK: - Decline Job
        private func declineJob() {
            let db = Firestore.firestore()
            
            db.collection("tow_requests").document(job.id).updateData([
                "status": "Declined"
            ]) { error in
                if let error = error {
                    print("Error declining job: \(error.localizedDescription)")
                } else {
                    print("Job declined successfully!")
                    presentationMode.wrappedValue.dismiss() // Dismiss the job details view
                }
            }
        }
    }
    
    // MARK: - Preview
    struct AvailableJobView_Previews: PreviewProvider {
        static var previews: some View {
            AvailableJobView()
        }
    }
}
