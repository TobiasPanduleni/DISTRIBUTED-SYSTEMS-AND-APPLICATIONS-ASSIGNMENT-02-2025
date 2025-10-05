import ballerina/http;
import ballerina/io;

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

type ticketRequest record {
    int user_id;
    int trip_id;
    string ticket_type;
    float price;
};

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

http:Client url = check new("http://localhost:9090/ticketingSystem");

function registerPassenger() returns error? {
    string username1 = io:readln("Enter username: ");
    string password1 = io:readln("Enter password: ");
    string email1 = io:readln("Enter email: ");
    registerRequest req = {
        username: username1,
        password: password1,
        email: email1,
        userRole: "passenger"
    };
    string response = check url->post("/registerPassenger", req);
    io:println(response);
}

function loginPassenger() returns error? {
    string username1 = io:readln("Enter email: ");
    string password1 = io:readln("Enter password: ");
    loginRequest req = {
        username: username1,
        password: password1
    };
    string response = check url->post("/loginPassenger", req);
    io:println(response);
}

function requestTicket() returns error? {
    string userId = check io:readln("Enter your user ID: ");
    string tripId = check io:readln("Enter trip ID: ");
    string ticketType = io:readln("Enter ticket type (single/multi/pass): ");
    string price = check io:readln("Enter ticket price: ");

    int userIDInt = check int:fromString(userId);
    int tripIDInt = check int:fromString(tripId);
    float priceFloat = check float:fromString(price);

    ticketRequest req = {
        user_id: userIDInt,
        trip_id: tripIDInt,
        ticket_type: ticketType,
        price: priceFloat
    };
    string response = check url->post("/ticketRequest", req);
    io:println(response);
}

function viewTickets() returns error? {
    tickets[] ticketList = check url->get("/ticketInformation");
    foreach var ticket in ticketList {
        io:println("Ticket Code: " + ticket.ticket_code + ", State: " + ticket.state + ", Price: " + ticket.price.toString());
    }
}

public function main() returns error? {
    while true {
        io:println("\n--- Smart Ticketing Client ---");
        io:println("1. Register");
        io:println("2. Login");
        io:println("3. Request Ticket");
        io:println("4. View Tickets");
        io:println("5. Exit");
        string choice = io:readln("Choose an option: ");
        match choice {
            "1" => {
                check registerPassenger();
            }
            "2" => {
                check loginPassenger();
            }
            "3" => {
                check requestTicket();
            }
            "4" => {
                check viewTickets();
            }
            "5" => {
                io:println("Exiting...");
                break;
            }
            _ => {io:println("Invalid option. Try again.");}
        }
    }
}