package com.hospital.hms.controller;

import com.hospital.hms.entity.Bill;
import com.hospital.hms.service.BillService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bills")
public class BillController {

    private final BillService billService;

    public BillController(BillService billService) {
        this.billService = billService;
    }

    // Create a bill: POST /api/bills?patientId=1&appointmentId=2 (appointmentId optional)
    @PostMapping
    public ResponseEntity<Bill> create(@RequestParam Long patientId,
                                        @RequestParam(required = false) Long appointmentId,
                                        @RequestBody Bill bill) {
        return ResponseEntity.status(HttpStatus.CREATED).body(billService.create(patientId, appointmentId, bill));
    }

    @GetMapping
    public ResponseEntity<List<Bill>> getAll() {
        return ResponseEntity.ok(billService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Bill> getById(@PathVariable Long id) {
        return ResponseEntity.ok(billService.getById(id));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<Bill>> getByPatient(@PathVariable Long patientId) {
        return ResponseEntity.ok(billService.getByPatient(patientId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Bill> update(@PathVariable Long id, @RequestBody Bill bill) {
        return ResponseEntity.ok(billService.update(id, bill));
    }

    @PatchMapping("/{id}/pay")
    public ResponseEntity<Bill> markAsPaid(@PathVariable Long id) {
        return ResponseEntity.ok(billService.markAsPaid(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        billService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
