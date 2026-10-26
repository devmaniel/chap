package com.chap.server.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** One of the built-in friends. Read-only: rows come from migrations. Not named Character to avoid java.lang. */
@Entity
@Table(name = "characters")
public class AiCharacter {

    @Id
    private UUID id;

    private String slug;

    private String name;

    private String tagline;

    private String bio;

    private String home;

    private String voiceLabel;

    private String firstHello;

    private String persona;

    @JdbcTypeCode(SqlTypes.ARRAY)
    private List<String> interests;

    private String elevenlabsVoiceId;

    protected AiCharacter() {
    }

    public UUID getId() {
        return id;
    }

    public String getSlug() {
        return slug;
    }

    public String getName() {
        return name;
    }

    public String getTagline() {
        return tagline;
    }

    public String getBio() {
        return bio;
    }

    public String getHome() {
        return home;
    }

    public String getVoiceLabel() {
        return voiceLabel;
    }

    public String getFirstHello() {
        return firstHello;
    }

    public String getPersona() {
        return persona;
    }

    public List<String> getInterests() {
        return interests;
    }

    public String getElevenlabsVoiceId() {
        return elevenlabsVoiceId;
    }
}
