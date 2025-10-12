package se.havochvatten.symphony.service;

import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import se.havochvatten.symphony.dto.UserDto;
import se.havochvatten.symphony.entity.UserSettings;
import se.havochvatten.symphony.exception.SymphonyModelErrorCode;
import se.havochvatten.symphony.exception.SymphonyStandardAppException;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.io.IOException;
import java.security.Principal;
import java.util.Map;

@Stateless
public class UserService {

    @PersistenceContext(unitName = "symphonyPU")
    private EntityManager em;
    private static final ObjectMapper mapper = new ObjectMapper();

    public UserDto getUser(Principal user) throws IOException {
        UserSettings settings = em.find(UserSettings.class, user.getName());
        return new UserDto(
            user.getName(),
            settings == null ? Map.of() : mapper.readerFor(Map.class).readValue(settings.getSettings())
        );
    }

    public void updateUserSettings(Principal userPrincipal, Map<String, Object> settings) throws SymphonyStandardAppException {
        UserSettings userSettings = em.find(UserSettings.class, userPrincipal.getName());
        if (userSettings == null) {
            userSettings = new UserSettings();
            userSettings.setUser(userPrincipal.getName());
        }
        try {
            userSettings.updateSettings(settings);
        } catch (JsonMappingException e) {
            throw new SymphonyStandardAppException(SymphonyModelErrorCode.OTHER_ERROR, e);
        }

        em.persist(userSettings);
    }
}
