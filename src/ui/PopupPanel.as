package ui {
    import mx.core.UIComponent;

    import spark.components.Group;

    import spark.components.Panel;

    public class PopupPanel extends Panel {
        public function PopupPanel() {
        }

        public function dispose():void {
        }

        public function close():void {
            dispose();
            (owner as Group).removeElement(this);
        }
    }
}
