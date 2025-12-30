import { LightningElement, wire } from 'lwc';
import getLoggedInEmployeeId from '@salesforce/apex/SAS_Employee_Controller.getLoggedInEmployeeId';

export default class EmployeeProfile extends LightningElement {
    employee;

    @wire(getLoggedInEmployeeId)
    wiredEmployee({ data, error }) {
        if (data) {
            this.employee = data;
        } else if (error) {
            console.error(error);
        }
    }

    get photoUrl() {
        return this.employee?.User__r?.FullPhotoUrl;
    }
}
