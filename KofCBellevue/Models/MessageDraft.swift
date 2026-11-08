import Foundation
struct MessageDraft {
    var subject: String
    var body = ""
    var useSMS = true
    var useEmail = true
    var phone = ""
    var email = ""
    init(date: Date = Date()) {
        subject = "KofC: Message — " + date.formatted(date: .long, time: .omitted)
    }
    var preview: String {
        let value = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? body : value
    }
    var smsBody: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? body : subject + "\n\n" + body
    }
    var isValid: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (useSMS || useEmail) &&
        (!useSMS || !phone.isEmpty) && (!useEmail || !email.isEmpty)
    }
}
