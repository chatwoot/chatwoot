<template>
    <woot-modal
        modal-type="right-aligned"
        show
        :on-close="onClose"
    >
        <div class="forward">
            <div class="forward__title">
                <h1 class="forward__title-primary">Compartilhar mensagem</h1>
                <p>Compartilhe a mensagem com seus contatos do Converx</p>
            </div>
            <div class="forward__contacts">
                <div class="forward__contacts-search">
                    <label for="Procurar um contato">Procurar um contato</label>
                    <div>
                        <input
                            type="search"
                            name="contact"
                            id="contact"
                            v-model="searchQuery"
                            @keyup.enter="onSearchSubmit"
                            @input="onInputSearch"
                            @search="resetSearch"
                        >
                    </div>
                </div>
                <form class="form-contact" action="#" method="post" @submit.prevent="onSubmit">
                    <div class="forward__contacts-list">
                        <div class="contact contact-columns">
                            <div class="contact-id">&nbsp;</div>
                            <div class="contact-name">Contato</div>
                            <div class="contact-phone">Telefone</div>
                            <div class="contact-date">Última Atividade</div>
                        </div>
                        <div class="contacts">
                            <div class="contact" v-for="contact in contacts">
                                <div class="contact-id">
                                    <label><input type="checkbox" name="contactIds[]" :value="contact.id"></label>
                                </div>
                                <div class="contact-name">
                                    <div class="contact-thumbnail">
                                        <img v-if="contact.thumbnail" :src="contact.thumbnail" :alt="contact.name">
                                    </div>
                                    <div>{{contact.name}}</div>
                                </div>
                                <div class="contact-phone">{{contact.phone_number}}</div>
                                <div class="contact-date">
                                    <time-ago
                                        :last-activity-timestamp="contact.last_activity_at"
                                        :created-at-timestamp="contact.created_at"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="forward__contacts-footer">
                        <woot-button :disabled="showEmptySearchResult">Encaminhar</woot-button>
                    </div>
                </form>
            </div>
        </div>
    </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import TimeAgo from 'dashboard/components/ui/TimeAgo';

const DEFAULT_PAGE = 1;

export default {
    mixins: [alertMixin],
    components: {
        TimeAgo,
    },
    props: {
        message: {
            type: Object
        }
    },
    data() {
        return {
            searchQuery: '',
        }
    },
    computed: {
        ...mapGetters({
            contacts: 'contacts/getContacts',
        }),
        showEmptySearchResult() {
            return !!this.searchQuery && this.contacts.length === 0;
        },
    },
    mounted() {
        this.fetchContacts(DEFAULT_PAGE);
    },
    methods: {
        onClose() {
            this.$emit('close');
        },
        updatePageParam(page) {
            window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
        },
        fetchContacts(page) {
            this.updatePageParam(page);
            let value = this.searchQuery;
            if (this.searchQuery.charAt(0) === '+') {
                value = this.searchQuery.substring(1);
            }

            const requestParams = {
                page,
                sortAttr: '-last_activity_at',
            };

            if (!value) {
                this.$store.dispatch('contacts/get', requestParams);
            } else {
                this.$store.dispatch('contacts/search', {
                    search: encodeURIComponent(value),
                    ...requestParams,
                });
            }
        },
        onSearchSubmit() {
            if (!this.searchQuery) return;
            this.fetchContacts(DEFAULT_PAGE);
        },
        onInputSearch(event) {
            const newQuery = event.target.value;
            const refetchAllContacts = !!this.searchQuery && newQuery === '';
            this.searchQuery = newQuery;
            if (refetchAllContacts) {
                this.fetchContacts(DEFAULT_PAGE);
            }
        },
        resetSearch(event) {
            const newQuery = event.target.value;
            if (!newQuery) {
                this.searchQuery = newQuery;
                this.fetchContacts(DEFAULT_PAGE);
            }
        },
        onSubmit(event) {
            const formData = new FormData(event.target);
            const contactIds = formData.getAll('contactIds[]')

            this.$store.dispatch('forwardMessage', {
                conversationId: this.message.conversation_id,
                messageId: this.message.id,
                contacts: contactIds
            });

            this.showAlert("Encaminhando mensagem...");
            this.onClose();
        }
    }
}
</script>

<style lang="scss">
.modal-mask .modal--close {
    z-index: 1;
}
.forward {
    background: #fff;
    padding: 10px;
    position: relative;
    height: 100%;
    min-width: 430px;
    &__title {
        text-align: left;
        &-primary {
            font-size: 1.5rem;
        }
    }
    &__contacts {
        &-search {
            label {
                font-size: 1rem;
                margin-top: 15px;
            }
        }
        .form-contact {
            padding: 0;
        }
        &-list {
            > .contacts {
                background: #F8FAFC;
                overflow-y: auto;
                overflow-x: hidden;
                position: absolute;
                left: 10px;
                right: 10px;
                bottom: 60px;
                top: 160px;
                &::-webkit-scrollbar {
                  width: 6px;
                }

                &::-webkit-scrollbar-thumb {
                    border-radius: 3px;
                    background: #3c4858;
                }
            }
            .contact {
                display: flex;
                border-bottom: 1px solid;
                &:last-child {
                    border-bottom: 0;
                }
                &-columns {
                    border-bottom: 0;
                    min-height: 25px;
                    margin-top: -12px;
                }
                &-id {
                    width: 30px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    label {
                        margin-top: 10px;
                    }
                }
                &-name {
                    display: flex;
                    margin: 0 10px;
                    align-items: center;
                    flex-grow: 1;
                }
                &-thumbnail {
                    width: 32px;
                    height: 32px;
                    margin-right: 10px;
                    margin-bottom: 10px;
                    margin-top: 10px;
                    img {
                        border-radius: 50%;
                    }
                }
                &-phone {
                    min-width: 110px;
                    display: flex;
                    align-items: center;
                }
                &-date {
                    min-width: 90px;
                    display: flex;
                    align-items: center;
                    > .time-ago {
                        margin: auto;
                    }
                }
            }
        }
        &-footer {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: #fff;
            padding: 10px;
            display: flex;
            justify-content: flex-end;
            max-height: 60px;
        }
    }
}
</style>