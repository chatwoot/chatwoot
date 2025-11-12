<template>
    <div class="example-simple">
        <h1 id="example-title" class="example-title">Simple Example</h1>
        <div class="upload">
            <ul>
                <li v-for="file in files" :key="file.id">
                    <span>{{ file.name }}</span> - <span>{{ $formatSize(file.size) }}</span> -
                    <span>{{ file.magic }}</span>
                    <span v-if="file.error">{{ file.error }}</span>
                    <span v-else-if="file.success">success</span>
                    <span v-else-if="file.active">active</span>
                    <span v-else-if="!!file.error">{{ file.error }}</span>
                    <span v-else></span>
                </li>
            </ul>
            <div class="example-btn">
                <file-upload class="btn btn-primary" post-action="/upload/post" extensions="gif,jpg,jpeg,png,webp"
                    accept="image/png,image/gif,image/jpeg,image/webp" :multiple="true" :size="1024 * 1024 * 10"
                    v-model="files" @input-filter="inputFilter" @input-file="inputFile" ref="upload">
                    <i class="fa fa-plus"></i>
                    Select files
                </file-upload>
                <button type="button" class="btn btn-success" v-if="!upload || !upload.active"
                    @click.prevent="upload.active = true">
                    <i class="fa fa-arrow-up" aria-hidden="true"></i>
                    Start Upload
                </button>
                <button type="button" class="btn btn-danger" v-else @click.prevent="upload.active = false">
                    <i class="fa fa-stop" aria-hidden="true"></i>
                    Stop Upload
                </button>
            </div>
        </div>
        <div class="pt-5 source-code">
            Source code:
            <a
                href="https://github.com/lian-yue/vue-upload-component/blob/master/docs/views/examples/AsyncEvents.vue">/docs/views/examples/AsyncEvents.vue</a>
        </div>
    </div>
</template>
<style>
.example-simple label.btn {
    margin-bottom: 0;
    margin-right: 1rem;
}
</style>

<script>
import { ref } from "vue";
import FileUpload from "vue-upload-component";
import CryptoJS from "crypto-js";
import { fileTypeFromBuffer } from "file-type";

export default {
    components: {
        FileUpload,
    },

    setup(props, context) {
        const upload = ref(null);

        const files = ref([]);

        async function inputFilter(newFile, oldFile, prevent) {
            if (newFile && !oldFile) {
                // Before adding a file
                // 添加文件前

                // Filter system files or hide files
                // 过滤系统文件 和隐藏文件
                if (/(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/.test(newFile.name)) {
                    return prevent();
                }

                // Filter php html js file
                // 过滤 php html js 文件
                if (/\.(php5?|html?|jsx?)$/i.test(newFile.name)) {
                    return prevent();
                }


                // read file md5
                if (!newFile.md5 && newFile.file) {
                    prevent();

                    // wait 2 seconds
                    setTimeout(async function () {
                        newFile.md5 = await calculateMD5(newFile.file);
                        upload.value.add(newFile, 0);
                    }, 2000);
                    return;
                }


                // async magic
                if (!newFile.magic && newFile.file && newFile.fileObject) {
                    newFile.fileObject = false;
                    newFile.status = "mime processing";
                    newFile.magic = {};

                    setTimeout(async function () {
                        try {
                            const chunk = newFile.file.slice(0, 128); // 读取前 128 个字节
                            const arrayBuffer = await chunk.arrayBuffer();
                            const magic = await fileTypeFromBuffer(new Uint8Array(arrayBuffer));
                            upload.value.update(newFile, {
                                magic: magic,
                                fileObject: true,
                            });
                        } catch (e) {
                            // error
                            upload.value.update(newFile, {
                                error: e.code || e.error || e.message || e,
                                fileObject: true,
                            });
                        }
                    }, 1000);
                }
            }
        }

        function inputFile(newFile, oldFile) {
            if (newFile && !oldFile) {
                // add
                console.log("add", newFile);
            }
            if (newFile && oldFile) {
                // update
                console.log("update", newFile);
            }

            if (!newFile && oldFile) {
                // remove
                console.log("remove", oldFile);
            }
        }

        function calculateMD5(blob) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();

                // 读取完成后处理
                reader.onloadend = function () {
                    // 将结果转换为 WordArray
                    const wordArray = CryptoJS.lib.WordArray.create(reader.result);

                    // 计算 MD5
                    const md5 = CryptoJS.MD5(wordArray).toString();
                    resolve(md5);
                };

                // 读取错误处理
                reader.onerror = function (error) {
                    reject(error);
                };

                // 将 Blob 读取为 ArrayBuffer
                reader.readAsArrayBuffer(blob);
            });
        }

        return {
            files,
            upload,
            inputFilter,
            inputFile,
        };
    },
};
</script>
