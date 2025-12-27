import { LightningElement, track, wire } from 'lwc';
import getBlockSummaries from '@salesforce/apex/SAS_Block_Controller.getBlockSummaries';
import { subscribe, MessageContext } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
import APPROVAL_REFRESH from '@salesforce/messageChannel/BlockSummaryRefresh__c';

export default class BlockSummaryTable extends LightningElement {
    @track data = [];
    @track columns = [];
    @track isLoading = true;

    wiredResult; // store wired result for refreshApex
    subscription;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // ------- Wire Apex method -------
    @wire(getBlockSummaries)
    wiredBlocks(result) {
        this.wiredResult = result; // store for refresh
        if (result.data) {
            this.processData(result.data);
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.isLoading = false;
        }
    }

    // ------- Subscribe to LMS -------
    subscribeToMessageChannel() {
        if (this.subscription) return; // already subscribed

        this.subscription = subscribe(
            this.messageContext,
            APPROVAL_REFRESH,
            (message) => {
                if (message.refresh) {
                    refreshApex(this.wiredResult); // ✅ refresh data
                }
            }
        );
    }

    // ------- Process data for datatable -------
    processData(result) {
        if (!result || result.length === 0) {
            this.data = [];
            this.columns = [];
            return;
        }

        const baseColumns = [
            { label: 'Block Name', fieldName: 'blockName' },
            { label: 'Location', fieldName: 'location' },
            { label: 'Total Seats', fieldName: 'totalSeats', type: 'number' },
            { label: 'Daily Seats Remaining', fieldName: 'dailyAvailable', type: 'number' }
        ];

        const groupSet = new Set();
        result.forEach(block => {
            Object.keys(block.groupCounts || {}).forEach(groupName => {
                groupSet.add(groupName);
            });
        });

        const dynamicColumns = [...groupSet].map(g => ({
            label: `Group ${g} Remaining`,
            fieldName: `group_${g}`,
            type: 'number'
        }));

        this.columns = [...baseColumns, ...dynamicColumns];

        this.data = result.map(b => {
            let row = { ...b };
            [...groupSet].forEach(groupName => {
                row[`group_${groupName}`] = b.groupCounts[groupName] || 0;
            });
            return row;
        });
    }
}
