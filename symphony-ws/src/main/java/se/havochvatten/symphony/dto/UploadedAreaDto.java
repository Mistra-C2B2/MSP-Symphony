package se.havochvatten.symphony.dto;

import java.util.List;

public class UploadedAreaDto {
    public Integer srid;
    public List<String> featureIdentifiers;
    public String key;

    public UploadedAreaDto() {}

    public UploadedAreaDto(List<String> featureIdentifiers, Integer srid, String key) {
        this.featureIdentifiers = featureIdentifiers;
        this.srid = srid;
        this.key = key;
    }
}
