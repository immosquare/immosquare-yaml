YML_HASH = {
  "en" => {
    "demo"                    => "demo", 
    "demo2"                   => {
      "demo2-1" => {
        "demo2-1-1" => "hello", 
        "demo2-1-2" => nil, 
        "demo2-1-3" => "John Doe"
      }
    }, 
    "description1"            => "This is the first line of test.\nThis is the second line of test.\nThis is the third line of test.", 
    "description2"            => "This is the first line of test.\nThis is the second line of test.\nThis is the third line of test.\n",
    "description3"            => "  This is the first line of test.\n  This is the second line of test.\n  This is the third line of test.", 
    "description4"            => "This is the first line of test. This is the second line of test. This is the third line of test.\n",
    "emoji"                   => "\"Here's an emoji: 😀\"", 
    "\"no\""                  => "Neither is this", 
    "some_special_characters" => {
      "special1" => "\"-hyphen\"", 
        "special2" => "\"*asterisk\"", 
        "special3" => "\"%percent\"", 
        "special4" => "\",comma\"", 
        "special5" => "\"!exclamation\"", 
        "special6" => "\"?question_mark\"", 
        "special7" => "\"&ampersand\"", 
        "special8" => "\"#hash\"", "special9" => "\"@at\""
    }, 
    "\"yes\""                 => "This is not a boolean"
  }
}.freeze