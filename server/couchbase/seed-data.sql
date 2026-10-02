-- Sample data for the mobile_sync bucket.
-- Run in the Couchbase Query Workbench (or with cbq) AFTER the bucket, scope and collections exist.
-- The document ID of each `users` document is the login name typed in the app (case-sensitive).

UPSERT INTO mobile_sync.mainscope.users (KEY, VALUE) VALUES
("alice", {
  "Name": "alice",
  "membershipNumber": "EK-123456789",
  "tierStatus": "Gold",
  "miles": 1000,
  "tierMiles": 1500,
  "phoneNumber": "12345678",
  "airline": "Emirates",
  "flightNumber": "EK 203",
  "departureCity": "Dubai",
  "destinationCity": "Riyadh",
  "departureTime": "13:00",
  "arrivalTime": "15:00",
  "duration": "2h",
  "note": ""
}),
("bob", {
  "Name": "bob",
  "membershipNumber": "EK-987654321",
  "tierStatus": "Platinum",
  "miles": 7000,
  "tierMiles": 15000,
  "phoneNumber": "33501234599",
  "airline": "Emirates",
  "flightNumber": "EK 215",
  "departureCity": "Dubai",
  "destinationCity": "Las Vegas",
  "departureTime": "08:30",
  "arrivalTime": "12:30",
  "duration": "16h",
  "note": ""
});

-- A single document drives the banner message shown on the Welcome screen.
-- Change it on the server and watch the app update live.
UPSERT INTO mobile_sync.mainscope.shared (KEY, VALUE) VALUES
("content", {
  "message": "Hello from Couchbase!",
  "color": "red",
  "size": 24
});
