public class SAS_Cycle_Group_Scheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        SAS_Cycle_Group_Rotator.rotateGroups();
    }
}