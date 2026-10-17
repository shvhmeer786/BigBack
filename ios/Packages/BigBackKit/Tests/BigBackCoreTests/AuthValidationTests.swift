import Testing
@testable import BigBackCore

@Suite("Sign-up email rules")
struct EmailRuleTests {
    @Test func acceptsUWAddresses() {
        #expect(AuthValidation.emailProblem("maya.chen@uwaterloo.ca") == nil)
        #expect(AuthValidation.emailProblem("  Maya.Chen@UWaterloo.CA ") == nil)
        #expect(AuthValidation.emailProblem("j3smith@edu.uwaterloo.ca") == nil)
    }

    @Test func rejectsOtherDomainsAndLookalikes() {
        #expect(AuthValidation.emailProblem("maya@gmail.com") == .notUW)
        #expect(AuthValidation.emailProblem("x@notuwaterloo.ca") == .notUW)
        #expect(AuthValidation.emailProblem("x@uwaterloo.ca.evil.com") == .notUW)
    }

    @Test func rejectsEmptyAndMalformed() {
        #expect(AuthValidation.emailProblem("   ") == .empty)
        #expect(AuthValidation.emailProblem("maya") == .malformed)
        #expect(AuthValidation.emailProblem("@uwaterloo.ca") == .malformed)
        #expect(AuthValidation.emailProblem("a@b@uwaterloo.ca") == .malformed)
        #expect(AuthValidation.emailProblem("maya chen@uwaterloo.ca") == .malformed)
    }
}

@Suite("Usernames and codes")
struct HandleAndCodeTests {
    @Test(arguments: ["maya", "maya.chen", "ari_eats", "abc", String(repeating: "a", count: 24)])
    func validHandles(_ handle: String) {
        #expect(AuthValidation.isValidHandle(handle))
    }

    @Test(arguments: ["", "ab", "no spaces", "émile", "maya!", String(repeating: "a", count: 25)])
    func invalidHandles(_ handle: String) {
        #expect(!AuthValidation.isValidHandle(handle))
    }

    @Test func suggestionsFromEmail() {
        #expect(AuthValidation.suggestedHandle(fromEmail: "Maya.Chen@uwaterloo.ca") == "maya.chen")
        #expect(AuthValidation.suggestedName(fromEmail: "maya.chen@uwaterloo.ca") == "Maya Chen")
        #expect(AuthValidation.suggestedName(fromEmail: "j-lee_2@uwaterloo.ca") == "J Lee 2")
    }

    @Test func codesKeepSixDigitsOnly() {
        #expect(AuthValidation.cleanCode("482 913") == "482913")
        #expect(AuthValidation.cleanCode("12345678") == "123456")
        #expect(AuthValidation.cleanCode("12a3") == "123")
    }
}
