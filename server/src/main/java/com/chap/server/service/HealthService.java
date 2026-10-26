package com.chap.server.service;

import com.chap.server.repository.HealthRepository;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

@Service
public class HealthService {

    private final HealthRepository healthRepository;

    public HealthService(HealthRepository healthRepository) {
        this.healthRepository = healthRepository;
    }

    public void check() {
        try {
            healthRepository.ping();
        } catch (DataAccessException ex) {
            throw new DomainException(DomainException.Kind.UNAVAILABLE, "database_unavailable",
                    "The database can't be reached.");
        }
    }
}
