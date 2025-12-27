import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import EMPLOYEE_OBJECT from '@salesforce/schema/Employee__c';
import REQUEST_OBJECT from '@salesforce/schema/Request__c';
import GROUP_FIELD from '@salesforce/schema/Employee__c.Group__c';
import TYPE_FIELD from '@salesforce/schema/Request__c.Type__c';

import getBlocks from '@salesforce/apex/SAS_Block_Controller.getBlocks';
import getAvailableSeats from '@salesforce/apex/SAS_Employee_Controller.getAvailableSeats';
import getLoggedInEmployeeId from '@salesforce/apex/SAS_Employee_Controller.getLoggedInEmployeeId';
import createRequest from '@salesforce/apex/SAS_Request_Controller.createRequest';

export default class NewRequestModal extends NavigationMixin(LightningElement) {

    @api isOpen = false;

    selectedBlock;
    isClosed = false;
    selectedGroup;
    selectedType;
    reason;
    availableSeats;
    loggedInEmployee;

    blockOptions = [];
    groupOptions = [];
    typeOptions = [];

    get showAvailableSeats() {
        return this.availableSeats !== null && this.availableSeats !== undefined;
    }

    @wire(getObjectInfo, { objectApiName: EMPLOYEE_OBJECT })
    empObjectInfo;

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    reqObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$empObjectInfo.data.defaultRecordTypeId',
        fieldApiName: GROUP_FIELD
    })
    groupPicklist({ data }) {
        if (data) this.groupOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$reqObjectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    typePicklist({ data }) {
        if (data) this.typeOptions = data.values;
    }

    @wire(getLoggedInEmployeeId)
    wiredEmp({ data }) {
        if (data) this.loggedInEmployee = data;
    }

    connectedCallback() {
        getBlocks().then(data => {
            this.blockOptions = data.map(b => ({
                label: b.Name,
                value: b.Id
            }));
        });
    }

    handleBlockChange(e) {
        this.selectedBlock = e.detail.value;
        this.fetchSeats();
    }

    handleGroupChange(e) {
        this.selectedGroup = e.detail.value;
        this.fetchSeats();
    }

    handleTypeChange(e) {
        this.selectedType = e.detail.value;
    }

    handleReasonChange(e) {
        this.reason = e.detail.value;
    }

    fetchSeats() {
        if (!this.selectedBlock || !this.selectedGroup) {
            this.availableSeats = null;
            return;
        }
        getAvailableSeats({
            blockId: this.selectedBlock,
            groupName: this.selectedGroup
        }).then(seats => {
            this.availableSeats = seats;
        });
    }

    handleSubmit() {

        if (!this.selectedType || !this.selectedBlock || !this.selectedGroup || !this.reason) {
            this.showError('All fields are mandatory.');
            return;
        }

        if (!this.availableSeats || this.availableSeats <= 0) {
            this.showError('No available seats available.');
            return;
        }

        if (
            this.loggedInEmployee &&
            this.loggedInEmployee.Block__c === this.selectedBlock &&
            this.loggedInEmployee.Group__c === this.selectedGroup
        ) {
            this.showError('You cannot request for your current Block and Group.');
            return;
        }

        console.log(this.loggedInEmployee.Id, typeof this.loggedInEmployee.Id);
        console.log(this.selectedBlock, typeof this.selectedBlock);
        console.log(this.selectedGroup, typeof this.selectedGroup);
        console.log(this.reason, typeof this.reason);
        console.log(this.loggedInEmployee.Id, typeof this.loggedInEmployee.Id);

        createRequest({
            requestType: this.selectedType,
            blockId: this.selectedBlock,
            groupName: this.selectedGroup,
            reason: this.reason,
            empId: this.loggedInEmployee.Id
        })
        .then((requestId) => {
            this.closeModal();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Request submitted successfully',
                    variant: 'success'
                })
            );
            
            this.dispatchEvent(
                new CustomEvent('requestcreated', {
                    detail: { requestId: requestId }
                })
            );

            

            
        })
        .catch(err => {
            this.showError(err?.body?.message || 'Submission failed');
        });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
        this.isClosed = true;
    }

    showError(msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error'
            })
        );
    }
}
