# Hospital Management System

Spring Boot 3 / Java 17 / Maven REST API covering:

- **Authentication** — JWT-based register/login, role-based access (`ADMIN`, `DOCTOR`, `RECEPTIONIST`)
- **Patient Management** — CRUD
- **Doctor Management** — CRUD, filter by specialization
- **Appointment Booking** — book, reschedule, update status, cancel, list by patient/doctor
- **Billing** — generate bills (tied to patient + optional appointment), mark as paid
- **Prescription Management** — CRUD, list by patient/doctor

Uses an in-memory H2 database, so there's nothing to install — it runs standalone.

## Prerequisites

- JDK 17+
- Maven 3.8+ (or use the included `mvnw` wrapper if you add one — this project assumes `mvn` is on your PATH)

## 1. Build

```bash
cd hospital-management-system
mvn clean install
```

## 2. Run

```bash
mvn spring-boot:run
```

The app starts on **http://localhost:8080**.

On first startup a default admin user is seeded:
```
username: admin
password: admin123
```

H2 console (optional, to inspect data): http://localhost:8080/h2-console
JDBC URL: `jdbc:h2:mem:hospitaldb`, user `sa`, blank password.

## 3. Test it locally (curl walkthrough)

All endpoints except `/api/auth/**` require a `Bearer` JWT token.

### a. Login as the seeded admin
```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```
Copy the `token` value from the response into a shell variable:
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
echo $TOKEN
```

### b. Register another user (optional)
```bash
curl -s -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"drjones","password":"pass1234","role":"DOCTOR"}'
```

### c. Create a doctor
```bash
curl -s -X POST http://localhost:8080/api/doctors \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Dr. Jones","specialization":"Cardiology","email":"jones@hospital.com","phone":"9999999999","consultationFee":500}'
```

### d. Create a patient
```bash
curl -s -X POST http://localhost:8080/api/patients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","age":35,"gender":"Male","email":"john@example.com","phone":"8888888888","address":"12 Main St","bloodGroup":"O+"}'
```

### e. Book an appointment (patientId=1, doctorId=1 from above)
```bash
curl -s -X POST "http://localhost:8080/api/appointments?patientId=1&doctorId=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"appointmentTime":"2026-08-10T10:30:00","reason":"Chest pain checkup"}'
```

### f. Add a prescription
```bash
curl -s -X POST "http://localhost:8080/api/prescriptions?patientId=1&doctorId=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"medicines":"Atorvastatin 10mg - once daily x 30 days","notes":"Recheck lipid profile in 1 month"}'
```

### g. Generate a bill (appointmentId optional)
```bash
curl -s -X POST "http://localhost:8080/api/bills?patientId=1&appointmentId=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"consultationFee":500,"medicineCharges":250,"otherCharges":50}'
```

### h. Mark the bill as paid
```bash
curl -s -X PATCH "http://localhost:8080/api/bills/1/pay" \
  -H "Authorization: Bearer $TOKEN"
```

### i. Fetch everything back
```bash
curl -s http://localhost:8080/api/patients -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8080/api/doctors -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8080/api/appointments -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8080/api/bills -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8080/api/prescriptions -H "Authorization: Bearer $TOKEN"
```

If every call above returns JSON (not a 401/403), the system is working end-to-end.

## API summary

| Feature       | Method & Path                                  |
|---------------|-------------------------------------------------|
| Auth          | `POST /api/auth/register`, `POST /api/auth/login` |
| Patients      | `GET/POST /api/patients`, `GET/PUT/DELETE /api/patients/{id}` |
| Doctors       | `GET/POST /api/doctors`, `GET/PUT/DELETE /api/doctors/{id}`, `GET /api/doctors?specialization=X` |
| Appointments  | `POST /api/appointments?patientId=&doctorId=`, `GET /api/appointments`, `GET /api/appointments/{id}`, `GET /api/appointments/patient/{id}`, `GET /api/appointments/doctor/{id}`, `PUT /api/appointments/{id}`, `PATCH /api/appointments/{id}/status?status=`, `DELETE /api/appointments/{id}` |
| Billing       | `POST /api/bills?patientId=&appointmentId=`, `GET /api/bills`, `GET /api/bills/{id}`, `GET /api/bills/patient/{id}`, `PUT /api/bills/{id}`, `PATCH /api/bills/{id}/pay`, `DELETE /api/bills/{id}` |
| Prescriptions | `POST /api/prescriptions?patientId=&doctorId=`, `GET /api/prescriptions`, `GET /api/prescriptions/{id}`, `GET /api/prescriptions/patient/{id}`, `GET /api/prescriptions/doctor/{id}`, `PUT /api/prescriptions/{id}`, `DELETE /api/prescriptions/{id}` |

## Notes / next steps for production

- Swap the H2 datasource in `application.properties` for MySQL/PostgreSQL (add the driver dependency in `pom.xml`).
- Move `jwt.secret` out of `application.properties` into an environment variable.
- Add role-based `@PreAuthorize` checks on controller methods if you want e.g. only `ADMIN`/`RECEPTIONIST` to create bills.
- Add pagination to the `GET` list endpoints once data volume grows.
