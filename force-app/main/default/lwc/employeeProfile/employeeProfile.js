import { LightningElement, wire } from 'lwc';
import getLoggedInEmployeeId from '@salesforce/apex/SAS_Employee_Controller.getLoggedInEmployeeId';
import { subscribe, MessageContext } from 'lightning/messageService';
import EMPLOYEE_PROFILE_REFRESH from '@salesforce/messageChannel/EmployeeProfileRefresh__c';
import { refreshApex } from '@salesforce/apex';

export default class EmployeeProfile extends LightningElement {
    
    employee;
    subscription;
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // ------- Subscribe to LMS -------
    subscribeToMessageChannel() {
        if (this.subscription) return; // already subscribed

        this.subscription = subscribe(
            this.messageContext,
            EMPLOYEE_PROFILE_REFRESH,
            (message) => {
                if (message.refresh) {
                    refreshApex(this.wiredEmployee); // ✅ refresh data
                    console.log('Employee Profile Refreshed');
                }
            }
        );
    }


    @wire(getLoggedInEmployeeId)
    wiredEmployee(result) {
        this.wiredEmployee = result;
        if (result.data) {
            this.employee = result.data;
        } else if (result.error) {
            console.error(result.error);
        }
    }

    get photoUrl() {
        return this.employee?.User__r?.FullPhotoUrl;
    }
}
