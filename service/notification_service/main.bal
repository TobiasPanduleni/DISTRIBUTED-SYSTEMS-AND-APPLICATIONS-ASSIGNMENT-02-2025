import ballerinax/kafka;
import ballerina/http;

service /ticketingSystem on new http:Listener(9090){
    private final kafka:Producer trips_producer;

    function init() returns error? {
        self.trips_producer = check new(kafka:DEFAULT_URL);
    }

    resource function post notify(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        
        check self.trips_producer->send({
            topic: "notifications",
            value: payload.toString()
        });
        check caller->respond("Notification sent");
    }
}
