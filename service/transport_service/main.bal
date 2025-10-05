import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/http;
import ballerinax/kafka;

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
    private final kafka:Producer transport_producer;

    function init() returns error? {
        self.db_client = check new ("localhost", "root", "password", "logistics_db",3306);
        self.transport_producer = check new(kafka:DEFAULT_URL);
    }

    resource function post create_route(create_route req) returns string|error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO routes (route_code, origin, destination) VALUES (${req.route_code}, ${req.origin}, ${req.destination})`;
        sql:ExecutionResult|sql:Error result = check self.db_client->execute(insertQuery);
        if result is sql:ExecutionResult {
            return "Route created successfully";
        } else {
            return error("Failed to create route: " + result.message());
        }   
    }

    resource function post create_trips(trips req) returns string|error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO trips (route_id, vehicle_id, start_time, end_time, status) VALUES (${req.route_id}, ${req.vehicle_id}, ${req.start_time}, ${req.end_time}, ${req.status})`;
        _ = check self.transport_producer->send({topic: "trip.created", value: req.vehicle_id});
        sql:ExecutionResult|sql:Error result = check self.db_client->execute(insertQuery);
        
        if result is sql:ExecutionResult {
            return "Trip created successfully";
        } else {
            return error("Failed to create trip: " + result.message());
        }
    }

    resource function put updateTrip(trips req) returns string|error? {
        sql:ParameterizedQuery updateQuery = `UPDATE trips SET vehicle_id = ${req.vehicle_id}, start_time = ${req.start_time}, end_time = ${req.end_time}, status = ${req.status} WHERE id = ${req.id}`;
        sql:ExecutionResult|sql:Error result = check self.db_client->execute(updateQuery);
        _ = check self.transport_producer->send({topic: "trip.updated", value: req.vehicle_id});
        if result is sql:ExecutionResult {
            return "Trip updated successfully";
        } else {
            return error("Failed to update trip: " + result.message());
        }
    }

    resource function get listTrips() returns trips[]|error? {
        stream<trips, sql:Error?> tripsStream = self.db_client->query(`SELECT * FROM trips`);
        
        return from trips trip in tripsStream
               select trip; 
    }
}