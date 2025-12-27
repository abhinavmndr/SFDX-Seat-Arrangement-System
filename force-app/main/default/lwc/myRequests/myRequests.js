import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyRequests from '@salesforce/apex/SAS_Request_Controller.getMyRequests';
import { refreshApex } from '@salesforce/apex';

export default class MyRequests extends NavigationMixin(LightningElement) {

    allRequests = [];
    isModalOpen = false;
    wiredResult;
        
    columns = [
        {
            label: 'Request Name',
            type: 'button',
            fieldName: 'Name',
            typeAttributes: {
                label: { fieldName: 'Name' },
                name: 'openRecord',
                variant: 'base'
            }
        },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getMyRequests)
    wiredRequests(result) {
        this.wiredResult = result;
        if (result.data) {
            this.allRequests = result.data;
        }
    }

    /* Modal control */
    openModal() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    /* Child → Parent */
    handleRequestCreated() {
        this.isModalOpen = false;
        refreshApex(this.wiredResult);
    }

    /* Row navigation */
    handleRowAction(event) {
        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view'
            }
        });
    }
}
