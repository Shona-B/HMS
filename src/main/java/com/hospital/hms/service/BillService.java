package com.hospital.hms.service;

import com.hospital.hms.entity.Appointment;
import com.hospital.hms.entity.Bill;
import com.hospital.hms.entity.Patient;
import com.hospital.hms.exception.ResourceNotFoundException;
import com.hospital.hms.repository.AppointmentRepository;
import com.hospital.hms.repository.BillRepository;
import com.hospital.hms.repository.PatientRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BillService {

    private final BillRepository billRepository;
    private final PatientRepository patientRepository;
    private final AppointmentRepository appointmentRepository;

    public BillService(BillRepository billRepository,
                        PatientRepository patientRepository,
                        AppointmentRepository appointmentRepository) {
        this.billRepository = billRepository;
        this.patientRepository = patientRepository;
        this.appointmentRepository = appointmentRepository;
    }

    public Bill create(Long patientId, Long appointmentId, Bill billDetails) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id: " + patientId));

        billDetails.setPatient(patient);

        if (appointmentId != null) {
            Appointment appointment = appointmentRepository.findById(appointmentId)
                    .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id: " + appointmentId));
            billDetails.setAppointment(appointment);
        }

        billDetails.calculateTotal();
        return billRepository.save(billDetails);
    }

    public List<Bill> getAll() {
        return billRepository.findAll();
    }

    public Bill getById(Long id) {
        return billRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found with id: " + id));
    }

    public List<Bill> getByPatient(Long patientId) {
        return billRepository.findByPatientId(patientId);
    }

    public Bill markAsPaid(Long id) {
        Bill bill = getById(id);
        bill.setPaid(true);
        return billRepository.save(bill);
    }

    public Bill update(Long id, Bill updated) {
        Bill bill = getById(id);
        bill.setConsultationFee(updated.getConsultationFee());
        bill.setMedicineCharges(updated.getMedicineCharges());
        bill.setOtherCharges(updated.getOtherCharges());
        bill.calculateTotal();
        return billRepository.save(bill);
    }

    public void delete(Long id) {
        Bill bill = getById(id);
        billRepository.delete(bill);
    }
}
