import { LightningElement } from 'lwc';

export default class ScreenQuickActionDemo extends LightningElement {
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}