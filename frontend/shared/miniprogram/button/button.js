Component({
  properties: {
    text: { type: String },
    type: { type: String, value: "primary" },
    size: { type: String, value: "medium" },
    disabled: { type: Boolean, value: false },
    loading: { type: Boolean, value: false },
    block: { type: Boolean, value: false },
  },
  
  methods: {
    handleClick() {
      if (!this.data.disabled && !this.data.loading) {
        this.triggerEvent('click');
      }
    },
  }
});