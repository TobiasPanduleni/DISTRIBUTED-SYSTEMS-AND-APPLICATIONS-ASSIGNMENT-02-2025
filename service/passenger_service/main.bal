import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/kafka;
import ballerina/http;
import ballerina/io;
enum role {
    passenger,
    admin,
    validator
};
public type Users record {
    int id;
    string name;
    string email;
    string password;
    string userRole;
    float walletBalance;
    string createdAt;
};

type registerRequest record {
    string username;
    string email;
    string password;
    string userRole;
};

type loginRequest record {
    string username;
    string password;
};

enum ticketState {
    CREATED,
    PAID,
    VALIDATED,
    EXPIRED
};

enum ticketType {
    single,
    multi,
    pass
}

type tickets record {
    int id;
    string ticket_code;
    int user_id;
    int trip_id;
    string ticket_type;
    float price;
    string state;
    string createdAt;
    string expires_at;
};

type ticketRequest record {
    int user_id;
    int trip_id;
    string ticket_type;
    float price;
};



service /ticketingSystem on new http:Listener(9090){
    private final mysql:Client db_client;
    private final kafka:Producer passenger_producer;
    private final kafka:Producer ticket_producer;

    function init() returns error? {
        self.passenger_producer = check new(kafka:DEFAULT_URL);
        self.ticket_producer = check new(kafka:DEFAULT_URL);
        self.db_client = check new ("127.0.0.1", "root", "password", "smart_ticketing",3306);
    }

    resource function post registerPassenger(registerRequest req) returns string|error? {
        sql:ParameterizedQuery q = `SELECT * FROM users WHERE email = ${req.email}`;
        ///Users|sql:Error result =  check self.db_client->queryRow(q);
        
        ///if result is sql:NoRowsError{
         sql:ExecutionResult|sql:Error insertResult = check self.db_client->execute(
            `INSERT INTO users (username, email, password_hash, role, wallet_balance) 
             VALUES (${req.username}, ${req.email}, ${req.password}, 'passenger', 0.0)`
        );

        _ = check self.passenger_producer->send({topic: "passenger.registered", value: req.username});
        if insertResult is sql:ExecutionResult{
            return "Registration successful";
        }
        else if insertResult is sql:Error{
            return error("Registration failed: " + insertResult.message());
        }
        ///}
       
        ///else {
        ///    return error("Database error");
        ///}
    }
    resource function post loginPassenger(loginRequest req) returns string|error? {
        Users|sql:Error result =  check self.db_client->queryRow(`SELECT * FROM users WHERE email = ${req.username} AND password = ${req.password}`);
        
        if result is Users {
            return "Login successful";
        } 
        else if result is sql:NoRowsError {
            return "Invalid username or password";
        } 
        else {
            return error("Database error");
        }
    }

    resource function post ticketRequest(ticketRequest req) returns  string|error? {
        string ticketCode = "TICKET" + req.user_id.toString() + req.trip_id.toString();
        sql:ParameterizedQuery insertQuery = `INSERT INTO tickets (ticket_code, user_id, trip_id, ticket_type, price, state, createdAt, expires_at) VALUES (${ticketCode}, ${req.user_id}, ${req.trip_id}, ${req.ticket_type}, ${req.price}, ${CREATED}, CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 HOUR))`;
        sql:ExecutionResult|sql:Error result = check self.db_client->execute(insertQuery);
        _ = check self.ticket_producer->send({topic: "ticket.requested", value: ticketCode});
        if result is sql:ExecutionResult {
            return "Ticket created successfully with code: " + ticketCode;
        } else {
            return error("Failed to create ticket: " + result.message());
        }
        
    }

    resource function get ticketInformation() returns tickets[]|error? {
        stream<tickets, sql:Error?> ticketsStream = self.db_client->query(`SELECT * FROM tickets`);
        
        return from tickets ticket in ticketsStream
               select ticket; 
    }
    
}

listener kafka:Listener passenger_listener = new(kafka:DEFAULT_URL, {
    topics: "passenger.registered"
});

service on passenger_listener {
    remote function onConsumerRecord(Users[] passengers) returns error? {

      foreach var passenger in passengers {
         io:println("New passenger registered: " + passenger.name );
      }
    }
}

