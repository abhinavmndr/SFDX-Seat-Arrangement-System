public class CycleGroupScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        CycleGroupRotator.rotateGroups();
    }
}