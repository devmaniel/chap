package com.chap.server.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;

import com.chap.server.repository.HealthRepository;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.CannotGetJdbcConnectionException;

class HealthServiceTest {

    @Test
    void databaseDownIsUnavailable() {
        var repository = mock(HealthRepository.class);
        doThrow(new CannotGetJdbcConnectionException("down")).when(repository).ping();

        assertThatThrownBy(() -> new HealthService(repository).check())
                .isInstanceOfSatisfying(DomainException.class, ex -> {
                    assertThat(ex.kind()).isEqualTo(DomainException.Kind.UNAVAILABLE);
                    assertThat(ex.code()).isEqualTo("database_unavailable");
                });
    }
}
