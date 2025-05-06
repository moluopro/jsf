// https://github.com/abner/flutter_js/blob/master/example/assets/js/ajv.js

var ajv = new global.Ajv({ allErrors: true, coerceTypes: true });

ajv.addSchema(
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
    }, "obj1");


const data = {
    id: -5,
    name: "Alice",
    email: "not-an-email",
    age: 22,
    student: true
    // need "worker"
  };

const valid = ajv.validate("obj1", data);

!valid ? ajv.errorsText() : "Yep"
