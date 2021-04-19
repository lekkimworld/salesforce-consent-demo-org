import { LightningElement, api } from 'lwc';
import getConsentData from "@salesforce/apex/AuthorizationFormDisplayController.getConsentData";
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class AuthorizationFormDisplay extends LightningElement {
    @api availableActions = [];
    @api navigateOnConsentDecision;
    @api consent = false;
    _dup;
    defaultId;
    languages;
    texts;
    selectedText;
    selectedLanguage;

    @api get authformTextId() {
        if (!this.selectedText) return undefined;
        return this.selectedText.id;
    }
    @api get dup() {
        return this._dup;
    }
    set dup(value) {
        this._dup = value;
        console.log(`Data Use Purpose set (${this._dup}) - loading data`);
        getConsentData({ "dataUsePurpose": this._dup }).then(data => {
            console.log("Loaded data", data);
            this.texts = data.texts.map(t => t).sort((a, b) => a.language.localeCompare(b.language));
            this.languages = this.texts.map(t => {
                return {
                    "label": t.language,
                    "value": t.locale
                }
            });
            this.defaultId = data.defaultId;
            if (!this.defaultId) {
                // use first as default
                this.defaultId = this.texts[0].id;
            }
            this.selectedText = this.texts.find(t => t.id === this.defaultId);
            this.selectedLanguage = this.selectedText.locale;
        })
    }

    handleLanguageChange(event) {
        this.selectedLanguage = event.detail.value;
        this.selectedText = Array.prototype.find.call(this.texts, t => t.locale === event.detail.value);
        console.log(`Language now: ${this.selectedLanguage}, authform text: ${this.selectedText.id}`);

        const attributeChangeEvent = new FlowAttributeChangeEvent('authformTextId', this.authformTextId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleConsentPositive() {
        this.handleConsentChange(true);
    }
    handleConsentNegative() {
        this.handleConsentChange(false);
    }
    handleConsentChange(status) {
        this.consent = status;
        console.log(`Consent now: ${this.consent}`);
        let attributeChangeEvent = new FlowAttributeChangeEvent('consent', this.consent);
        this.dispatchEvent(attributeChangeEvent);
        attributeChangeEvent = new FlowAttributeChangeEvent('authformTextId', this.authformTextId);
        this.dispatchEvent(attributeChangeEvent);
        console.log(`Navigate on consent decision: ${this.navigateOnConsentDecision}`);
        if (this.navigateOnConsentDecision) {
            if (this.availableActions.find(action => action === 'NEXT')) {
                let navigationEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigationEvent);
                console.log("Dispatched NEXT navigation event");
            } else if (this.availableActions.find(action => action === 'FINISH')) {
                let navigationEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigationEvent);
                console.log("Dispatched FINISH navigation event");
            }
        }
    }
}