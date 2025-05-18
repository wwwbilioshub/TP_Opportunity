trigger contactsDouble on SOBJECT (before insert) {
    // Rassembler les AccountId des nouveaux contacts et leurs emails
    Set<Id> accountIds = new Set<Id>();
    Map<Id, Set<String>> newEmailsByAccount = new Map<Id, Set<String>>();

    for (Contact c : Trigger.new) {
        if (c.AccountId != null && c.Email != null) {
            accountIds.add(c.AccountId);

            if (!newEmailsByAccount.containsKey(c.AccountId)) {
                newEmailsByAccount.put(c.AccountId, new Set<String>());
            }
            newEmailsByAccount.get(c.AccountId).add(c.Email.toLowerCase());
        }
    }

    // Charger tous les contacts existants liés à ces comptes
    Map<Id, Set<String>> existingEmailsByAccount = new Map<Id, Set<String>>();
    for (Contact existing : [
        SELECT Email, AccountId FROM Contact
        WHERE AccountId IN :accountIds AND Email != null
    ]) {
        String email = existing.Email.toLowerCase();
        Id accId = existing.AccountId;

        if (!existingEmailsByAccount.containsKey(accId)) {
            existingEmailsByAccount.put(accId, new Set<String>());
        }
        existingEmailsByAccount.get(accId).add(email);
    }

    // Vérifier les doublons et ajouter des erreurs si besoin
    for (Contact c : Trigger.new) {
        if (c.AccountId != null && c.Email != null) {
            String newEmail = c.Email.toLowerCase();
            Id accId = c.AccountId;

            // Vérifie contre les contacts existants
            if (existingEmailsByAccount.containsKey(accId) &&
                existingEmailsByAccount.get(accId).contains(newEmail)) {
                c.addError('Un contact avec cet email existe déjà sur ce compte.');
            }

            // Vérifie contre les autres enregistrements dans Trigger.new (batch insert)
            for (Contact other : Trigger.new) {
                if (other != c && other.AccountId == accId &&
                    other.Email != null && other.Email.toLowerCase() == newEmail) {
                    c.addError('Un autre contact en cours d’insertion a le même email sur ce compte.');
                }
            }
        }
    }
}
