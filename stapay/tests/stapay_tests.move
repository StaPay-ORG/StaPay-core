#[test_only]
module stapay::stapay_tests {
    // uncomment this line to import the module
    // use stapay::stapay;
    use std::ascii::string;
    use std::string::{String, utf8};

    const ENotImplemented: u64 = 0;

    #[test]
    fun test_stapay() {
        let str = b"Hello,".to_string();
        let another = b" World!".to_string();
        let res=str==another;
        assert!(res, 0);
    }
    // fun strings_are_equal(str1: String, str2: String): bool {
    //     vector::equals<byte>(string::bytes(&str1), string::bytes(&str2))
    // }

    // #[test]
    // fun test_stapay_fail() {
    //     abort ENotImplemented
    // }
}
