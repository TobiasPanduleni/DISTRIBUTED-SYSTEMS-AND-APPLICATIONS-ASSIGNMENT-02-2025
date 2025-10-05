import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/kafka;
import ballerina/http;

type route record {
    int id;
    string route_code;
    string origin;
    string destination;
    string createdAt;
};

type create_route record {
    string route_code;
    string origin;
    string destination;
};

enum Status {
    ON_TIME,
    DELAYED,
    CANCELLED
};

type trips record {
    int id;
    int route_id;
    string vehicle_id;
    string start_time;
    string end_time;
    string status;
};


service /ticketingSystem on new http:Listener(9090){
     private final mysql:Client db_client;
    private final kafka:Producer trips_producer;

    function init() returns error? {
        self.trips_producer = check new(kafka:DEFAULT_URL);
        self.db_client = check new ("127.0.0.1", "root", "password", "smart_ticketing",3306);
    }

    resource function post create_trip(trips req) returns string|error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO trips (route_id, vehicle_id, start_time, end_time, status) VALUES (${req.route_id}, ${req.vehicle_id}, ${req.start_time}, ${req.end_time}, ${req.status})`;
        _ = check self.trips_producer->send({topic: "trip.created", value: req.vehicle_id});
        sql:ExecutionResult|sql:Error result = check self.db_client->execute(insertQuery);

        if result is sql:ExecutionResult {
            return "Trip created successfully";
        } else {
            return error("Failed to create trip: " + result.message());
        }
    
    }
}