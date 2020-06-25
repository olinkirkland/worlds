package global.performance {
    public class PerformanceReport {
        public static var items:Array;
        public static var totalTime:Number;

        public static function addPerformanceReportItem(item:PerformanceReportItem):void {
            if (!items)
                reset();

            totalTime += item.timeTakenInSeconds;

            items.push(item);
            for each (item in items)
                item.percent = item.timeTakenInSeconds / totalTime;
        }

        public static function reset():void {
            items = [];
            totalTime = 0;
        }
    }
}
