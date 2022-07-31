<template>
	<modal :show.sync="show" :on-close="onClose" :close-on-backdrop-click="false">
		<div class="column content-box">
			<woot-modal-header
					:header-title="$t('INTEGRATION_SETTINGS.SHOPIFY.ADD.TITLE')"
					:header-content="
          useInstallationName(
            $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.DESC'),
            globalConfig.installationName
          )
        "
			/>
			<form class="row" @submit.prevent="addShopifyAccount">
				<div class="medium-12 columns">
					<label :class="{ error: $v.accountName.$error }">
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.LABEL') }}
						<input
								v-model.trim="accountName"
								type="text"
								name="accountName"
								:placeholder="
									$t(
									'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.PLACEHOLDER'
									)
								"
								@input="$v.accountName.$touch"
						/>
						<span v-if="$v.accountName.$error" class="message">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.ERROR') }}
						</span>
					</label>

					<label :class="{ error: $v.apiKey.$error }">
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.LABEL') }}
						<input
								v-model.trim="apiKey"
								type="text"
								name="apiKey"
								:placeholder="
									$t(
									'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.PLACEHOLDER'
									)
								"
								@input="$v.apiKey.$touch"
						/>
						<span v-if="$v.apiKey.$error" class="message">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.ERROR') }}
						</span>
					</label>

					<label :class="{ error: $v.apiSecret.$error }">
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.LABEL') }}
						<input
								v-model.trim="apiSecret"
								type="text"
								name="apiSecret"
								:placeholder="
									$t(
									'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.PLACEHOLDER'
									)
								"
								@input="$v.apiSecret.$touch"
						/>
						<span v-if="$v.apiSecret.$error" class="message">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.ERROR') }}
						</span>
					</label>

					<label :class="{ error: $v.redirectUrl.$error }">
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.LABEL') }}
						<input
								v-model.trim="redirectUrl"
								type="text"
								name="apiSecret"
								:placeholder="
								$t(
									'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.PLACEHOLDER'
								)
							"
								@input="$v.redirectUrl.$touch"
						/>
						<span v-if="$v.redirectUrl.$error" class="message">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.ERROR') }}
						</span>
					</label>
				</div>

				<div class="modal-footer">
					<div class="medium-12 columns">
						<woot-button class="button success" @click.prevent="onAuthorize">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.AUTHORIZE') }}
						</woot-button>
						<woot-button
								:disabled="$v.accountName.$invalid || $v.apiKey.$invalid || $v.apiSecret.$invalid || addShopify.showLoading"
								:is-loading="addShopify.showLoading"
						>
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.SUBMIT') }}
						</woot-button>
						<woot-button class="button clear" @click.prevent="onClose">
							{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.CANCEL') }}
						</woot-button>
					</div>
				</div>
			</form>
		</div>
	</modal>
</template>

<script>
import {required, url, minLength, maxLength} from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import Modal from '../../../../components/Modal';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import {mapGetters} from 'vuex';

export default {
	components: {
		Modal,
	},
	mixins: [alertMixin, globalConfigMixin],
	props: {
		onClose: {
			type: Function,
			required: true,
		},
	},
	data() {
		return {
			accountName: '',
			apiKey: "",
			apiSecret: "",
			addShopify: {
				showAlert: false,
				showLoading: false,
			},
			show: true,
		};
	},
	computed: {
		...mapGetters({globalConfig: 'globalConfig/get'}),
	},
	validations: {
		accountName: {
			required,
			minLength: minLength(3)
		},
		apiKey: {
			required,
			minLength: minLength(32),
			maxLength: maxLength(40)
		},
		apiSecret: {
			required,
			minLength: minLength(32),
			maxLength: maxLength(40)
		},
		redirectUrl: {
			required
		}
	},
	methods: {
		resetForm() {
			this.accountName = '';
			this.apiKey = '';
			this.apiSecret = '';
			this.redirectUrl = '';
			this.$v.accountName.$reset();
			this.$v.apiKey.$reset();
			this.$v.apiSecret.$reset();
			this.$v.redirectUrl.$reset();
		},
		onAuthorize(){
			this.showAlert("Authorized successfully");
		},
		async addShopifyAccount() {
			this.addShopify.showLoading = true;

			try {
				await this.$store.dispatch('shopify/create', {
					shopify: {
						account_name: this.accountName,
						api_key: this.apiKey,
						api_secret: this.apiSecret,
						redirect_url: this.redirectUrl
					},
				});
				this.addShopify.showLoading = false;

				this.addShopify.message = this.$t(
						'INTEGRATION_SETTINGS.SHOPIFY.ADD.API.SUCCESS_MESSAGE'
				);
				this.resetForm();
				this.onClose();
			} catch (error) {
				this.addShopify.showLoading = false;
				this.addShopify.message =
						error.response.data.message ||
						this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.ERROR_MESSAGE');
			} finally {
				this.addShopify.showLoading = false;
				this.showAlert(this.addShopify.message);
			}
		},
	},
};
</script>
