package global.performance {
    public class PerformanceReportItem {
        public var name:String;
        public var timeTakenInSeconds:Number;
        public var description:String;
        public var percent:Number;

        public function PerformanceReportItem(name:String, timeTakenInSeconds:Number, description:String = null) {
            this.name = name;
            this.timeTakenInSeconds = timeTakenInSeconds;
            this.description = description;
        }
    }
}
