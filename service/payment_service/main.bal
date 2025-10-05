import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/http;
type payments record {
    int id;
    int user_id;
    int ticket_id;
    float amount;
    string provider_ref;
    string status;
    string processed_at;
};

service /ticketingSystem/payments on new http:Listener(9090){
    private final mysql:Client dbClient;


    function init() returns error? {
        self.dbClient = check new ("localhost", "root", "password", "ticketing", 3306);
    }

    resource function put payment(payments paymentReq) returns string|error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO payments (user_id, ticket_id, amount, provider_ref, status, processed_at) VALUES (${paymentReq.user_id}, ${paymentReq.ticket_id}, ${paymentReq.amount}, ${paymentReq.provider_ref}, ${paymentReq.status}, ${paymentReq.processed_at})`;
        sql:ExecutionResult|sql:Error result = check self.dbClient->execute(insertQuery);
        if result is sql:ExecutionResult {
            return "Payment processed successfully";
        } else {
            return error("Failed to process payment: " + result.message());
        }
    }
}