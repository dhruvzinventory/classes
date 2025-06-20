import SwiftUI
import Foundation

// MARK: - Models
struct Student: Identifiable, Codable {
    var id = UUID()
    var name: String
    var phoneNumber: String
    var email: String
    var grade: String
    var enrolledSubjects: [String]
    var joiningDate: Date
    var isActive: Bool = true
}

struct ClassSession: Identifiable, Codable {
    var id = UUID()
    var subject: String
    var grade: String
    var startTime: Date
    var endTime: Date
    var dayOfWeek: String
    var maxStudents: Int
    var enrolledStudents: [UUID] = []
    var isActive: Bool = true
}

struct AttendanceRecord: Identifiable, Codable {
    var id = UUID()
    var studentId: UUID
    var classId: UUID
    var date: Date
    var isPresent: Bool
    var notes: String = ""
}

// MARK: - Data Manager
class ClassDataManager: ObservableObject {
    @Published var students: [Student] = []
    @Published var classes: [ClassSession] = []
    @Published var attendanceRecords: [AttendanceRecord] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Sample students
        students = [
            Student(name: "Rahul Sharma", phoneNumber: "+91-9876543210", email: "rahul@email.com", grade: "Group 1", enrolledSubjects: ["Company Law", "Corporate Governance"], joiningDate: Date()),
            Student(name: "Priya Singh", phoneNumber: "+91-9876543211", email: "priya@email.com", grade: "Group 2", enrolledSubjects: ["Securities Laws", "Banking Law"], joiningDate: Date()),
            Student(name: "Amit Kumar", phoneNumber: "+91-9876543212", email: "amit@email.com", grade: "Group 1", enrolledSubjects: ["Company Law", "Economics & Statistics"], joiningDate: Date())
        ]
        
        // Sample classes
        classes = [
            ClassSession(subject: "Company Law", grade: "Group 1", startTime: createTime(hour: 9, minute: 0), endTime: createTime(hour: 10, minute: 30), dayOfWeek: "Monday", maxStudents: 20),
            ClassSession(subject: "Corporate Governance", grade: "Group 1", startTime: createTime(hour: 11, minute: 0), endTime: createTime(hour: 12, minute: 30), dayOfWeek: "Monday", maxStudents: 15),
            ClassSession(subject: "Securities Laws", grade: "Group 2", startTime: createTime(hour: 14, minute: 0), endTime: createTime(hour: 15, minute: 30), dayOfWeek: "Tuesday", maxStudents: 18)
        ]
    }
    
    private func createTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
    
    func addStudent(_ student: Student) {
        students.append(student)
    }
    
    func addClass(_ classSession: ClassSession) {
        classes.append(classSession)
    }
    
    func markAttendance(studentId: UUID, classId: UUID, isPresent: Bool) {
        let record = AttendanceRecord(studentId: studentId, classId: classId, date: Date(), isPresent: isPresent)
        attendanceRecords.append(record)
    }
    
    func getStudentsForClass(_ classId: UUID) -> [Student] {
        guard let classSession = classes.first(where: { $0.id == classId }) else { return [] }
        return students.filter { student in
            classSession.enrolledStudents.contains(student.id)
        }
    }
    
    func enrollStudent(_ studentId: UUID, in classId: UUID) {
        if let index = classes.firstIndex(where: { $0.id == classId }) {
            if !classes[index].enrolledStudents.contains(studentId) {
                classes[index].enrolledStudents.append(studentId)
            }
        }
    }
}

// MARK: - Main App (Remove @main since it's already in the separate app file)

// MARK: - Content View
struct ContentView: View {
    @StateObject private var dataManager = ClassDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            StudentsView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Students")
                }
                .tag(1)
            
            ClassesView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Classes")
                }
                .tag(2)
            
            AttendanceView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Attendance")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var dataManager: ClassDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Ashish Arora CS Classes")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Company Secretary Excellence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Total Students", count: dataManager.students.count, color: .blue, icon: "person.3.fill")
                        StatCard(title: "Active Classes", count: dataManager.classes.filter { $0.isActive }.count, color: .green, icon: "book.fill")
                        StatCard(title: "CS Subjects", count: Set(dataManager.classes.map { $0.subject }).count, color: .orange, icon: "building.2.fill")
                        StatCard(title: "Today's Classes", count: getTodaysClasses().count, color: .purple, icon: "calendar")
                    }
                    
                    // Today's Schedule
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Schedule")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if getTodaysClasses().isEmpty {
                            Text("No classes scheduled for today")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(getTodaysClasses()) { classSession in
                                ClassScheduleCard(classSession: classSession)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private func getTodaysClasses() -> [ClassSession] {
        let today = Calendar.current.component(.weekday, from: Date())
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = dayNames[today]
        
        return dataManager.classes.filter { $0.dayOfWeek == todayName && $0.isActive }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Class Schedule Card
struct ClassScheduleCard: View {
    let classSession: ClassSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(classSession.subject)
                    .font(.headline)
                Text(classSession.grade)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(classSession.startTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("to \(formatTime(classSession.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Students View
struct StudentsView: View {
    @ObservedObject var dataManager: ClassDataManager
    @State private var showingAddStudent = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.students) { student in
                    StudentRow(student: student)
                }
            }
            .navigationTitle("Students")
            .toolbar {
                Button(action: { showingAddStudent = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddStudent) {
                AddStudentView(dataManager: dataManager)
            }
        }
    }
}

// MARK: - Student Row
struct StudentRow: View {
    let student: Student
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(student.name)
                .font(.headline)
            Text(student.grade)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Subjects: \(student.enrolledSubjects.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Student View
struct AddStudentView: View {
    @ObservedObject var dataManager: ClassDataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var grade = "Group 1"
    @State private var selectedSubjects: Set<String> = []
    
    let grades = ["Group 1", "Group 2"]
    let group1Subjects = ["Company Law", "Corporate Governance", "Economics & Statistics", "Financial Accounting"]
    let group2Subjects = ["Securities Laws", "Banking Law", "Insurance Law", "Foreign Exchange Management", "Corporate Restructuring"]
    
    var availableSubjects: [String] {
        return grade == "Group 1" ? group1Subjects : group2Subjects
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section("Academic Information") {
                    Picker("Group", selection: $grade) {
                        ForEach(grades, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .onChange(of: grade) { _ in
                        selectedSubjects.removeAll()
                    }
                    
                    Text("Select Subjects")
                        .font(.headline)
                    
                    ForEach(availableSubjects, id: \.self) { subject in
                        HStack {
                            Text(subject)
                            Spacer()
                            if selectedSubjects.contains(subject) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedSubjects.contains(subject) {
                                selectedSubjects.remove(subject)
                            } else {
                                selectedSubjects.insert(subject)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newStudent = Student(
                            name: name,
                            phoneNumber: phoneNumber,
                            email: email,
                            grade: grade,
                            enrolledSubjects: Array(selectedSubjects),
                            joiningDate: Date()
                        )
                        dataManager.addStudent(newStudent)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || selectedSubjects.isEmpty)
                }
            }
        }
    }
}

// MARK: - Classes View
struct ClassesView: View {
    @ObservedObject var dataManager: ClassDataManager
    @State private var showingAddClass = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.classes) { classSession in
                    ClassRow(classSession: classSession, dataManager: dataManager)
                }
            }
            .navigationTitle("Classes")
            .toolbar {
                Button(action: { showingAddClass = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddClass) {
                AddClassView(dataManager: dataManager)
            }
        }
    }
}

// MARK: - Class Row
struct ClassRow: View {
    let classSession: ClassSession
    @ObservedObject var dataManager: ClassDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(classSession.subject)
                    .font(.headline)
                Spacer()
                Text(classSession.dayOfWeek)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(classSession.grade)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(formatTime(classSession.startTime)) - \(formatTime(classSession.endTime))")
                    .font(.caption)
                Spacer()
                Text("\(classSession.enrolledStudents.count)/\(classSession.maxStudents) students")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Add Class View
struct AddClassView: View {
    @ObservedObject var dataManager: ClassDataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var subject = "Company Law"
    @State private var grade = "Group 1"
    @State private var dayOfWeek = "Monday"
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var maxStudents = 20
    
    let group1Subjects = ["Company Law", "Corporate Governance", "Economics & Statistics", "Financial Accounting"]
    let group2Subjects = ["Securities Laws", "Banking Law", "Insurance Law", "Foreign Exchange Management", "Corporate Restructuring"]
    let grades = ["Group 1", "Group 2"]
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var availableSubjects: [String] {
        return grade == "Group 1" ? group1Subjects : group2Subjects
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Class Details") {
                    Picker("Group", selection: $grade) {
                        ForEach(grades, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .onChange(of: grade) { _ in
                        subject = availableSubjects.first ?? ""
                    }
                    
                    Picker("Subject", selection: $subject) {
                        ForEach(availableSubjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker("Day", selection: $dayOfWeek) {
                        ForEach(days, id: \.self) { day in
                            Text(day).tag(day)
                        }
                    }
                }
                
                Section("Timing") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Capacity") {
                    Stepper("Max Students: \(maxStudents)", value: $maxStudents, in: 1...50)
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newClass = ClassSession(
                            subject: subject,
                            grade: grade,
                            startTime: startTime,
                            endTime: endTime,
                            dayOfWeek: dayOfWeek,
                            maxStudents: maxStudents
                        )
                        dataManager.addClass(newClass)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            subject = availableSubjects.first ?? ""
        }
    }
}

// MARK: - Attendance View
struct AttendanceView: View {
    @ObservedObject var dataManager: ClassDataManager
    @State private var selectedClass: ClassSession?
    @State private var showingClassPicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let selectedClass = selectedClass {
                    AttendanceSheet(classSession: selectedClass, dataManager: dataManager)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Select a class to mark attendance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Choose Class") {
                            showingClassPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Attendance")
            .toolbar {
                if selectedClass != nil {
                    Button("Change Class") {
                        showingClassPicker = true
                    }
                }
            }
            .sheet(isPresented: $showingClassPicker) {
                ClassPickerView(dataManager: dataManager, selectedClass: $selectedClass)
            }
        }
    }
}

// MARK: - Class Picker View
struct ClassPickerView: View {
    @ObservedObject var dataManager: ClassDataManager
    @Binding var selectedClass: ClassSession?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.classes.filter { $0.isActive }) { classSession in
                    Button(action: {
                        selectedClass = classSession
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(classSession.subject)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(classSession.grade) • \(classSession.dayOfWeek)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Attendance Sheet
struct AttendanceSheet: View {
    let classSession: ClassSession
    @ObservedObject var dataManager: ClassDataManager
    @State private var attendanceStatus: [UUID: Bool] = [:]
    
    var enrolledStudents: [Student] {
        dataManager.students.filter { student in
            classSession.enrolledStudents.contains(student.id) ||
            student.enrolledSubjects.contains(classSession.subject)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Class Info Header
            VStack(alignment: .leading, spacing: 8) {
                Text(classSession.subject)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(classSession.grade) • \(classSession.dayOfWeek)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Attendance List
            if enrolledStudents.isEmpty {
                Text("No students enrolled in this class")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(enrolledStudents) { student in
                        AttendanceRow(
                            student: student,
                            isPresent: attendanceStatus[student.id] ?? false
                        ) { isPresent in
                            attendanceStatus[student.id] = isPresent
                        }
                    }
                }
            }
            
            // Save Button
            if !enrolledStudents.isEmpty {
                Button("Save Attendance") {
                    saveAttendance()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .onAppear {
            // Initialize attendance status
            for student in enrolledStudents {
                attendanceStatus[student.id] = false
            }
        }
    }
    
    private func saveAttendance() {
        for student in enrolledStudents {
            let isPresent = attendanceStatus[student.id] ?? false
            dataManager.markAttendance(studentId: student.id, classId: classSession.id, isPresent: isPresent)
        }
    }
}

// MARK: - Attendance Row
struct AttendanceRow: View {
    let student: Student
    let isPresent: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.headline)
                Text(student.grade)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { onToggle(!isPresent) }) {
                HStack(spacing: 8) {
                    Image(systemName: isPresent ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isPresent ? .green : .gray)
                    Text(isPresent ? "Present" : "Absent")
                        .foregroundColor(isPresent ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
