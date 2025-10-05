import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/kafka;
import ballerina/io;
import ballerina/time;

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


listener kafka:Listener ticket_listener = new(kafka:DEFAULT_URL, {
    groupId: "ticket_service_group",
    topics: "ticket.requested"
});

service on ticket_listener {
    private final mysql:Client db_client;
    
    function init() returns error? {
        self.db_client = check new ("127.0.0.1", "root", "password", "smart_ticketing",3306);
    }

    remote function onConsumerRecord(ticketRequest[] requestedTickets) returns error? {
        foreach var req in requestedTickets {
            io:println(`New ticket request received for user ID: ${req.user_id}` );

            // Generate ticket_code (simple random for demo)
            string ticket_code = string `TCKT-" + ${req.user_id} + "-" + ${req.trip_id}} `;
            // Set createdAt and expires_at
            string createdAt = time:utcNow().toString();
            string expires_at = time:utcNow().toString();

            // Insert ticket into DB
            var result = self.db_client->execute(
                `INSERT INTO tickets (ticket_code, user_id, trip_id, ticket_type, price, state, createdAt, expires_at)
                 VALUES (${ticket_code}, ${req.user_id}, ${req.trip_id}, ${req.ticket_type}, ${req.price}, 'CREATED', ${createdAt}, ${expires_at})`
            );
            if result is error {
                io:println("Error inserting ticket: ", result.message());
            } else {
                io:println("Ticket created and stored in DB for user ID: ", req.user_id);
            }
        }
    }
}