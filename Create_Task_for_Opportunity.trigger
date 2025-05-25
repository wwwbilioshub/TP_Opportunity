trigger CreateTask on Opportunity (after insert) {
    List<Task> tasksToCreate = new List<Task>();
    if(Trigger.isInsert){
      for (Opportunity opp : Trigger.new) {
        if (opp.Amount != null && opp.Amount > 10000 && opp.CloseDate >= Date.today()) {
            Task t = new Task();
            t.Subject = 'Suivi Opportunité Importante';
            t.Description = 'Créer une tâche de suivi pour une opportunité > 10k avec une date de clôture à venir.';
            t.Status = 'Not Started';
            t.Priority = 'Normal';
            t.WhatId = opp.Id;
            t.OwnerId = opp.OwnerId; // Assignée au propriétaire de l'opportunité
            tasksToCreate.add(t);
        }
    }

    if (!tasksToCreate.isEmpty()) {
        insert tasksToCreate;
    }  
    }
}
