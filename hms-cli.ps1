# ============================================================
# Hospital Management System - Interactive CLI
# ============================================================
# Usage: powershell -ExecutionPolicy Bypass -File hms-cli.ps1
# Make sure the Spring Boot app is already running on port 8080
# before starting this script.
# ============================================================

$BaseUrl = "http://localhost:8080"
$Global:Headers = $null

function Login {
    Write-Host "`n=== Login ===" -ForegroundColor Cyan
    $username = Read-Host "Username"
    $securePassword = Read-Host "Password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

    $body = @{ username = $username; password = $password } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body $body
        $Global:Headers = @{ Authorization = "Bearer $($response.token)" }
        Write-Host "Login successful. Welcome, $($response.username) [$($response.role)]" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Register {
    Write-Host "`n=== Register New User ===" -ForegroundColor Cyan
    $username = Read-Host "Username"
    $securePassword = Read-Host "Password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    Write-Host "Roles: ADMIN, DOCTOR, RECEPTIONIST"
    $role = Read-Host "Role"

    $body = @{ username = $username; password = $password; role = $role } | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/register" -Method Post -ContentType "application/json" -Body $body
        Write-Host $response -ForegroundColor Green
    } catch {
        Write-Host "Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Body = $null
    )
    try {
        if ($Body) {
            $json = $Body | ConvertTo-Json
            return Invoke-RestMethod -Uri "$BaseUrl$Path" -Method $Method -Headers $Global:Headers -ContentType "application/json" -Body $json
        } else {
            return Invoke-RestMethod -Uri "$BaseUrl$Path" -Method $Method -Headers $Global:Headers
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message -ForegroundColor Red
        }
        return $null
    }
}

function Prompt-Field($label, $default = $null) {
    if ($default) {
        $val = Read-Host "$label [$default]"
        if ([string]::IsNullOrWhiteSpace($val)) { return $default }
        return $val
    }
    return Read-Host $label
}

# ---------------- PATIENTS ----------------
function Menu-Patients {
    do {
        Write-Host "`n--- Patient Management ---" -ForegroundColor Yellow
        Write-Host "1. List all patients"
        Write-Host "2. Get patient by ID"
        Write-Host "3. Create patient"
        Write-Host "4. Update patient"
        Write-Host "5. Delete patient"
        Write-Host "0. Back to main menu"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Invoke-Api GET "/api/patients" | Format-Table -AutoSize }
            "2" {
                $id = Read-Host "Patient ID"
                Invoke-Api GET "/api/patients/$id" | Format-List
            }
            "3" {
                $body = @{
                    name = Prompt-Field "Name"
                    age = [int](Prompt-Field "Age")
                    gender = Prompt-Field "Gender"
                    email = Prompt-Field "Email"
                    phone = Prompt-Field "Phone"
                    address = Prompt-Field "Address"
                    bloodGroup = Prompt-Field "Blood Group"
                }
                Invoke-Api POST "/api/patients" $body | Format-List
            }
            "4" {
                $id = Read-Host "Patient ID to update"
                $body = @{
                    name = Prompt-Field "Name"
                    age = [int](Prompt-Field "Age")
                    gender = Prompt-Field "Gender"
                    email = Prompt-Field "Email"
                    phone = Prompt-Field "Phone"
                    address = Prompt-Field "Address"
                    bloodGroup = Prompt-Field "Blood Group"
                }
                Invoke-Api PUT "/api/patients/$id" $body | Format-List
            }
            "5" {
                $id = Read-Host "Patient ID to delete"
                Invoke-Api DELETE "/api/patients/$id" | Out-Null
                Write-Host "Deleted (if it existed)." -ForegroundColor Green
            }
        }
    } while ($choice -ne "0")
}

# ---------------- DOCTORS ----------------
function Menu-Doctors {
    do {
        Write-Host "`n--- Doctor Management ---" -ForegroundColor Yellow
        Write-Host "1. List all doctors"
        Write-Host "2. Get doctor by ID"
        Write-Host "3. Filter by specialization"
        Write-Host "4. Create doctor"
        Write-Host "5. Update doctor"
        Write-Host "6. Delete doctor"
        Write-Host "0. Back to main menu"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Invoke-Api GET "/api/doctors" | Format-Table -AutoSize }
            "2" {
                $id = Read-Host "Doctor ID"
                Invoke-Api GET "/api/doctors/$id" | Format-List
            }
            "3" {
                $spec = Read-Host "Specialization"
                Invoke-Api GET "/api/doctors?specialization=$spec" | Format-Table -AutoSize
            }
            "4" {
                $body = @{
                    name = Prompt-Field "Name"
                    specialization = Prompt-Field "Specialization"
                    email = Prompt-Field "Email"
                    phone = Prompt-Field "Phone"
                    consultationFee = [double](Prompt-Field "Consultation Fee")
                }
                Invoke-Api POST "/api/doctors" $body | Format-List
            }
            "5" {
                $id = Read-Host "Doctor ID to update"
                $body = @{
                    name = Prompt-Field "Name"
                    specialization = Prompt-Field "Specialization"
                    email = Prompt-Field "Email"
                    phone = Prompt-Field "Phone"
                    consultationFee = [double](Prompt-Field "Consultation Fee")
                    available = $true
                }
                Invoke-Api PUT "/api/doctors/$id" $body | Format-List
            }
            "6" {
                $id = Read-Host "Doctor ID to delete"
                Invoke-Api DELETE "/api/doctors/$id" | Out-Null
                Write-Host "Deleted (if it existed)." -ForegroundColor Green
            }
        }
    } while ($choice -ne "0")
}

# ---------------- APPOINTMENTS ----------------
function Menu-Appointments {
    do {
        Write-Host "`n--- Appointment Booking ---" -ForegroundColor Yellow
        Write-Host "1. List all appointments"
        Write-Host "2. Get appointment by ID"
        Write-Host "3. List by patient ID"
        Write-Host "4. List by doctor ID"
        Write-Host "5. Book new appointment"
        Write-Host "6. Reschedule appointment"
        Write-Host "7. Update status"
        Write-Host "8. Cancel appointment"
        Write-Host "0. Back to main menu"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Invoke-Api GET "/api/appointments" | Format-Table -AutoSize }
            "2" {
                $id = Read-Host "Appointment ID"
                Invoke-Api GET "/api/appointments/$id" | Format-List
            }
            "3" {
                $pid = Read-Host "Patient ID"
                Invoke-Api GET "/api/appointments/patient/$pid" | Format-Table -AutoSize
            }
            "4" {
                $did = Read-Host "Doctor ID"
                Invoke-Api GET "/api/appointments/doctor/$did" | Format-Table -AutoSize
            }
            "5" {
                $pid = Read-Host "Patient ID"
                $did = Read-Host "Doctor ID"
                $time = Prompt-Field "Appointment Time (yyyy-MM-ddTHH:mm:ss)"
                $reason = Prompt-Field "Reason"
                $body = @{ appointmentTime = $time; reason = $reason }
                Invoke-Api POST "/api/appointments?patientId=$pid&doctorId=$did" $body | Format-List
            }
            "6" {
                $id = Read-Host "Appointment ID to reschedule"
                $time = Prompt-Field "New Appointment Time (yyyy-MM-ddTHH:mm:ss)"
                $reason = Prompt-Field "Reason"
                $body = @{ appointmentTime = $time; reason = $reason }
                Invoke-Api PUT "/api/appointments/$id" $body | Format-List
            }
            "7" {
                $id = Read-Host "Appointment ID"
                Write-Host "Status options: SCHEDULED, COMPLETED, CANCELLED"
                $status = Read-Host "New status"
                Invoke-Api PATCH "/api/appointments/$id/status?status=$status" | Format-List
            }
            "8" {
                $id = Read-Host "Appointment ID to cancel"
                Invoke-Api DELETE "/api/appointments/$id" | Out-Null
                Write-Host "Cancelled (if it existed)." -ForegroundColor Green
            }
        }
    } while ($choice -ne "0")
}

# ---------------- BILLING ----------------
function Menu-Bills {
    do {
        Write-Host "`n--- Billing ---" -ForegroundColor Yellow
        Write-Host "1. List all bills"
        Write-Host "2. Get bill by ID"
        Write-Host "3. List by patient ID"
        Write-Host "4. Create bill"
        Write-Host "5. Update bill charges"
        Write-Host "6. Mark bill as paid"
        Write-Host "7. Delete bill"
        Write-Host "0. Back to main menu"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Invoke-Api GET "/api/bills" | Format-Table -AutoSize }
            "2" {
                $id = Read-Host "Bill ID"
                Invoke-Api GET "/api/bills/$id" | Format-List
            }
            "3" {
                $pid = Read-Host "Patient ID"
                Invoke-Api GET "/api/bills/patient/$pid" | Format-Table -AutoSize
            }
            "4" {
                $pid = Read-Host "Patient ID"
                $aid = Read-Host "Appointment ID (leave blank if none)"
                $consult = [double](Prompt-Field "Consultation Fee" "0")
                $med = [double](Prompt-Field "Medicine Charges" "0")
                $other = [double](Prompt-Field "Other Charges" "0")
                $body = @{ consultationFee = $consult; medicineCharges = $med; otherCharges = $other }
                $path = "/api/bills?patientId=$pid"
                if (-not [string]::IsNullOrWhiteSpace($aid)) { $path += "&appointmentId=$aid" }
                Invoke-Api POST $path $body | Format-List
            }
            "5" {
                $id = Read-Host "Bill ID to update"
                $consult = [double](Prompt-Field "Consultation Fee" "0")
                $med = [double](Prompt-Field "Medicine Charges" "0")
                $other = [double](Prompt-Field "Other Charges" "0")
                $body = @{ consultationFee = $consult; medicineCharges = $med; otherCharges = $other }
                Invoke-Api PUT "/api/bills/$id" $body | Format-List
            }
            "6" {
                $id = Read-Host "Bill ID to mark as paid"
                Invoke-Api PATCH "/api/bills/$id/pay" | Format-List
            }
            "7" {
                $id = Read-Host "Bill ID to delete"
                Invoke-Api DELETE "/api/bills/$id" | Out-Null
                Write-Host "Deleted (if it existed)." -ForegroundColor Green
            }
        }
    } while ($choice -ne "0")
}

# ---------------- PRESCRIPTIONS ----------------
function Menu-Prescriptions {
    do {
        Write-Host "`n--- Prescription Management ---" -ForegroundColor Yellow
        Write-Host "1. List all prescriptions"
        Write-Host "2. Get prescription by ID"
        Write-Host "3. List by patient ID"
        Write-Host "4. List by doctor ID"
        Write-Host "5. Create prescription"
        Write-Host "6. Update prescription"
        Write-Host "7. Delete prescription"
        Write-Host "0. Back to main menu"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Invoke-Api GET "/api/prescriptions" | Format-Table -AutoSize }
            "2" {
                $id = Read-Host "Prescription ID"
                Invoke-Api GET "/api/prescriptions/$id" | Format-List
            }
            "3" {
                $pid = Read-Host "Patient ID"
                Invoke-Api GET "/api/prescriptions/patient/$pid" | Format-Table -AutoSize
            }
            "4" {
                $did = Read-Host "Doctor ID"
                Invoke-Api GET "/api/prescriptions/doctor/$did" | Format-Table -AutoSize
            }
            "5" {
                $pid = Read-Host "Patient ID"
                $did = Read-Host "Doctor ID"
                $medicines = Prompt-Field "Medicines"
                $notes = Prompt-Field "Notes"
                $body = @{ medicines = $medicines; notes = $notes }
                Invoke-Api POST "/api/prescriptions?patientId=$pid&doctorId=$did" $body | Format-List
            }
            "6" {
                $id = Read-Host "Prescription ID to update"
                $medicines = Prompt-Field "Medicines"
                $notes = Prompt-Field "Notes"
                $body = @{ medicines = $medicines; notes = $notes }
                Invoke-Api PUT "/api/prescriptions/$id" $body | Format-List
            }
            "7" {
                $id = Read-Host "Prescription ID to delete"
                Invoke-Api DELETE "/api/prescriptions/$id" | Out-Null
                Write-Host "Deleted (if it existed)." -ForegroundColor Green
            }
        }
    } while ($choice -ne "0")
}

# ---------------- MAIN MENU ----------------
function Main-Menu {
    do {
        Write-Host "`n=====================================" -ForegroundColor Cyan
        Write-Host "   Hospital Management System - CLI " -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host "1. Patient Management"
        Write-Host "2. Doctor Management"
        Write-Host "3. Appointment Booking"
        Write-Host "4. Billing"
        Write-Host "5. Prescription Management"
        Write-Host "6. Register a new user"
        Write-Host "7. Re-login (switch user)"
        Write-Host "0. Exit"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" { Menu-Patients }
            "2" { Menu-Doctors }
            "3" { Menu-Appointments }
            "4" { Menu-Bills }
            "5" { Menu-Prescriptions }
            "6" { Register }
            "7" { Login }
        }
    } while ($choice -ne "0")
    Write-Host "Goodbye!" -ForegroundColor Cyan
}

# ---------------- ENTRY POINT ----------------
Write-Host "Connecting to Hospital Management System at $BaseUrl ..." -ForegroundColor Cyan
if (Login) {
    Main-Menu
} else {
    Write-Host "Cannot proceed without login. Exiting." -ForegroundColor Red
}