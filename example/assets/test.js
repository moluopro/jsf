// https://github.com/abner/flutter_js/blob/master/example/assets/js/ajv.js

var test = new global.Ajv({ allErrors: true, coerceTypes: true });

test.addSchema(
    {
        required: ["name", "age", "id", "email", "student", "worker"],
        "properties": {
            "id": {
                "minimum": 0,
                "type": "number"
            },
            "name": {
                "type": "string"
            },
            "email": {
                "type": "string",
                "format": "email"
            },
            "age": {
                "minimum": 0,
                "type": "number"
            },
            "student": {
                "type": "boolean"
            },
            "worker": {
                "type": "boolean"
            }
        }
    }, "someone");


(() => {
    const data = {
        id: -5,
        name: "Alice",
        email: "not-an-email",
        age: 22,
        student: true
        // missing "worker"
    };

    const valid = test.validate("someone", data);
    return !valid ? test.errorsText() : "Yep";
})();
