import { LightningElement, api, track } from 'lwc';
import getContactConsentData from "@salesforce/apex/CommunicationConsentLCC.getContactConsentData";

export default class DisplayEmailConsent extends LightningElement {
    @api recordId;
    @track data;

    connectedCallback() {
        getContactConsentData({contactId: this.recordId}).then(data => {
            console.log(data);
            this.data = JSON.stringify(data);
        }).catch(err => {
            console.log(err);
        })
    }


    
}