# Лаборатори №5: API систем тест — Postman ба Newman

**Хичээл:** F.CSA313 — Программ хангамжийн чанарын баталгаа ба тест (2026)  
**Оюутан:** Б.Мөнгөншагай  
**Оюутны код:** B232270013

Бодит ажиллуулалтын хувилбарууд:

```text
$ node -v
v22.23.3
$ newman -v
6.2.1
```

## Зорилго

Лекц 5-ын тест дизайны таван алхмыг `POST /registrations` функцэд хэрэгжүүлж, Postman collection-ийг Newman-аар автоматжуулна. Багшийн өгсөн `server.js`-ийг өөрчлөлтгүй ашиглана.

## Ажиллуулах

Node.js 16+ болон Newman 6 шаардлагатай.

```sh
npm ci
node server.js
```

Өөр терминалд `npx newman run lab05-collection.json` ажиллуулна. Postman-д `lab05-collection.json`-ийг Import хийж, collection variable `baseUrl=http://localhost:3000` ашиглана. T01 нь Даалгавар 1-ийн B231234567, CS313, CS201 жишээг яг хэрэгжүүлж, POST-д статус 201 ба result="OK" гэсэн хоёр тусдаа `pm.test`, мөн registrationID-ийн төрөл шалгах oracle агуулна.

Энэ орчинд Node.js урьдчилан суулгаагүй байсан тул `/tmp/lab05-tools` дотор түр байршуулсан. Одоогийн орчинд дараах командыг эхэлж өгч болно:

```sh
export PATH="$(cat /tmp/lab05-tools/node-path.txt):$PATH"
```

Node.js өөрийн машинд суусан бол энэ PATH тохируулга шаардлагагүй. `npm ci` нь package-lock.json дахь Newman-ийн хувилбарыг суулгана.

## Тест дизайны 5 алхам

1. Бие даан тестлэгдэх функц: `POST /registrations`; PUT endpoint-ууд зөвхөн initialization, POST-ийн хариу oracle болно.
2. Сонголтууд: оюутны оршин байх ба төлөв, үзсэн хичээл, хичээлийн оршин байх, урьдач нөхцөл, хүсэлтийн формат.
3. Төлөөлөх утгууд: доорх эквивалент анги тус бүрээс нэг утгыг сонгов.
4. Спецификаци: амжилт, дөрвөн бизнес алдаа, давхар алдаа, хязгаарын тохиолдлуудыг сонгов.
5. Бодит тест: спецификаци бүр тусдаа folder, өөрийн PUT setup, POST хүсэлт, `pm.test` oracle-уудтай байна.

## Сонголт ба төлөөлөх утга

| Сонголт | Эквивалент анги | Төлөөлөх утга |
|---|---|---|
| studentID | Байгаа, идэвхтэй | `B231234567`, status=`active` |
| studentID | Байгаа, идэвхгүй | `S03`, status=`inactive` |
| studentID | Байхгүй | `missing_student_{{$guid}}`, PUT хийхгүй |
| Оюутны үзсэн хичээл | Урьдач нөхцөл хангана | `["CS201", "CS202"]` |
| Оюутны үзсэн хичээл | Урьдач нөхцөл хангахгүй | `[]` эсвэл `["CS201"]` |
| courseID | Байгаа | `CS313`, PUT setup-тай |
| courseID | Байхгүй | `missing_course_{{$guid}}`, PUT хийхгүй |
| Хичээлийн урьдач нөхцөл | Бүгд үзсэн | required=`["CS201", "CS202"]`, taken ижил |
| Хичээлийн урьдач нөхцөл | Огт үзээгүй | required=`["CS201", "CS202"]`, taken=`[]` |
| Хичээлийн урьдач нөхцөл | Зарим нь үзсэн | required=`["CS201", "CS202"]`, taken=`["CS201"]` |
| Хичээлийн урьдач нөхцөл | Урьдач нөхцөлгүй | required=`[]`, taken=`[]` |
| Хүсэлтийн талбар | studentID дутуу | `{"courseID":"C10"}` |
| Хүсэлтийн талбар | courseID дутуу | `{"studentID":"S11"}` |
| Хүсэлтийн талбар | Хоосон ID | `{"studentID":"","courseID":"C12"}` |
| Хүсэлтийн формат | Буруу JSON | `{"studentID":` |

Үзсэн хичээл ба урьдач нөхцөл нь хоорондоо хамааралтай тул бүх сонголтын Cartesian үржвэрийг механикаар авахгүй. Байхгүй оюутанд status/coursesTaken, байхгүй хичээлд prerequisites оноох боломжгүй. Урьдач нөхцөлгүй хичээлд «зарим нь үзсэн» буюу «дутуу» анги боломжгүй.

## Спецификаци

| ID | Нөхцөл ба төлөөлөх оролт | HTTP | result | Нэмэлт oracle |
|---|---|---:|---|---|
| T01 | Active B231234567; CS201 үзсэн; CS313 requires CS201 | 201 | OK | registrationID тоо |
| T02 | Оюутан байхгүй; C02 байгаа | 200 | ERROR_NO_STUDENT | — |
| T03 | Inactive S03; C03 байгаа; prerequisites хангана | 200 | ERROR_INACTIVE_STUDENT | — |
| T04 | Active S04; хичээл байхгүй | 200 | ERROR_NO_COURSE | — |
| T05 | Active S05; taken=[]; C05 requires CS201, CS202 | 200 | ERROR_PREREQUISITES | missing=[CS201, CS202] |
| T06 | Active S06; taken=[CS201]; C06 requires CS201, CS202 | 200 | ERROR_PREREQUISITES | missing=[CS202] |
| T07 | Оюутан, хичээл хоёул байхгүй | 200 | ERROR_NO_STUDENT | Алдааны дараалал |
| T08 | Inactive S08; хичээл байхгүй | 200 | ERROR_INACTIVE_STUDENT | Алдааны дараалал |
| T09 | Active S09; taken=[]; C09 prerequisites=[] | 201 | OK | registrationID тоо |
| T10 | Student/course setup байгаа; POST-д studentID орхисон | 400 | ERROR_BAD_REQUEST | — |
| T11 | Student/course setup байгаа; POST-д courseID орхисон | 400 | ERROR_BAD_REQUEST | — |
| T12 | Student/course setup байгаа; POST-д studentID="" | 400 | ERROR_BAD_REQUEST | — |
| T13 | Student/course setup байгаа; POST body=`{"studentID":` | 400 | ERROR_BAD_JSON | — |

T07, T08-ын давхар алдааны хүлээлтийг серверийн шалгалтын дарааллаас таамаглаж, бодит Newman ажиллуулалтаар баталсан: талбар → оюутан байгаа эсэх → active эсэх → хичээл байгаа эсэх → prerequisites.

## Collection ба test independence

Үндсэн collection нь 13 спецификаци, 34 HTTP хүсэлт, **72 assertion** агуулна: setup PUT-уудын 42 assertion, POST хүсэлтүүдийн статус/result-ийн 26 assertion, registrationID ба missing-ийн 4 нэмэлт assertion. Спецификацийн тоо ба assertion-ы тоог ялган тоолов. Тест бүр өөрийн шаардлагатай student/course бичлэгийг PUT-ээр бүхэлд нь дахин тавьдаг. Байхгүй бичлэгийн кейсүүдэд тухайн бичлэгийг үүсгэхгүй; `{{$guid}}` шинэ ID ашигладаг тул бусад тест эсвэл өмнөх ажиллуулалтаас хамаарахгүй. T07-д хоёр бичлэг хоёул байхгүй байх нь setup-ийн зорилтот төлөв тул PUT хүсэлт байхгүй.

`registrationID`-г `1` гэх мэт тогтмол утгатай харьцуулаагүй, зөвхөн number төрөл шалгасан. `missing` массивт зөвхөн дутуу prerequisite-ууд яг орсон эсэхийг T05, T06-д шалгасан. Багшийн server.js-ийг өөрчлөөгүй.

## Newman автоматжуулалт ба нотолгоо

Бүх шаардлагатай нотолгоог шинээр үүсгэхдээ өмнөх серверээ зогсоогоод ажиллуулна:

```sh
npm ci
npm run verify
```

`scripts/run-evidence.sh` нь сервер асааж, PASS ба FAIL collection ажиллуулж, зөвхөн өөрийн асаасан процессыг зогсоогоод DOWN collection ажиллуулна. Порт 3000 дээр өөр процесс байвал түүнийг зогсоохгүй, тодорхой алдаа гаргана. Newman-ийн гаралтыг `tee`-ээр бүтнээр хадгалж, pipeline-ийн Newman exit code-ийг `${PIPESTATUS[0]}`-оор авна. `npm run verify` өөрөө шаардлагатай гурван үр дүнг зөв гарсан эсэхийг шалгаад exit 0 буцаана; зориуд алдаатай хоёр Newman ажиллуулалтын exit 1 нь тус тусын логт хадгалагдана.

| Ажиллуулалт | Нотолгоо | Iterations executed / failed | Requests executed / failed | Assertions executed / failed | Newman exit code |
|---|---|---|---|---|---:|
| PASS | [newman-pass.txt](results/newman-pass.txt) | 1 / 0 | 34 / 0 | **72 / 0** | **0** |
| Зориуд FAIL | [newman-fail.txt](results/newman-fail.txt) | 1 / 0 | 34 / 0 | **72 / 1** | **1** |
| Сервер DOWN | [newman-down.txt](results/newman-down.txt) | 1 / 0 | 34 / 34 | **72 / 72** | **1** |

`results/summary.json` дахь тоонуудыг Newman JSON reporter-оос авсан; дээрх хүснэгт бүрэн CLI логийн төгсгөлийн executed/failed тоонуудтай таарна.

FAIL collection-д зөвхөн T01 POST-ийн статус oracle-ийг зориуд 201-ээс 200 болгосон; үндсэн collection нь 201 хүлээсэн хэвээр. Бодит хариу 201 учраас нэг AssertionError гарч exit 1 болсон нь CI quality gate алдаатай oracle-ийг илрүүлж байгааг харуулна. DOWN логт `connect ECONNREFUSED` байна: энэ нь HTTP хариу авч чадаагүй интерфейсийн холболтын алдаа, харин FAIL нь амжилттай авсан HTTP хариунд буруу хүлээлт тавьсан oracle-ийн алдаа юм. DOWN үед хариу байхгүй тул статус/result oracle-ууд давхар унаж, 34 хүсэлтийн алдаа болон 72 assertion алдаа бүртгэгдсэн.

Нэмэлт давтан ажиллуулалтын нотолгоо: [newman-repeat.txt](results/newman-repeat.txt), нэг сервер дээр `newman run lab05-collection.json --iteration-count 2` ажиллуулж **2 iteration, 68 хүсэлт, 144 assertion, 0 failed, exit 0** авсан. Энэ тоо үндсэн PASS-ийн 72 assertion-ыг орлохгүй; давтан ажиллуулахад хуримтлагдсан registrationID тестийг эвдэхгүйг баталсан тусдаа шалгалт юм.

## Даалгавар 5: Нийтийн API (нэмэлт)

`lab05-public-collection.json` нь `GET https://jsonplaceholder.typicode.com/users`-д гурван тусдаа oracle шалгана: статус 200, хариу массив, эхний хэрэглэгчийн нэр `Leanne Graham`.

```sh
npx newman run lab05-public-collection.json
```

[newman-public.txt](results/newman-public.txt): **1 iteration, 1 хүсэлт, 3 assertion, 0 failed, exit 0**. Нийтийн GET-only API-д setup хэрэггүй тул тест бэлдэхэд хялбар боловч сүлжээ, гаднын үйлчилгээ ба өгөгдлийн өөрчлөлтөөс хамаарах нь локал API-аас хэцүү. Энэ тусдаа нэмэлт collection-ийн 3 assertion-ыг үндсэн PASS-ийн 72-т оруулаагүй.

## Дүгнэлт

Тест дизайны таван алхмаас спецификаци сонгох алхам хамгийн их бодол шаардсан.
Оюутны төлөв, хичээлийн оршин байх болон урьдач нөхцөлийн ангийг нэгтгэхдээ утгатай хослолуудыг сонгох хэрэгтэй байв.
Байхгүй оюутны идэвхтэй төлөв, байхгүй хичээлийн урьдач нөхцөл зэрэг хослол боломжгүй байлаа.
Урьдач нөхцөлгүй хичээлд зарим prerequisite дутуу гэсэн нөхцөл мөн боломжгүй.
Давхар алдааны кейсүүдээр оюутны оршин байх шалгалт хичээлийн шалгалтаас, оюутны идэвхтэй төлөв мөн хичээлийн шалгалтаас түрүүлдэг болохыг батлав.
Сонгосон спецификацийн хүрээнд серверийн функциональ согог илрээгүй бөгөөд энэ нь шалгаагүй бүх оролт зөв гэсэн баталгаа биш.
Хоосон coursesTaken нь prerequisite-тай хичээлд алдаа боловч prerequisite-гүй хичээлд амжилттайг ялгаж шалгав.
Бие даасан PUT setup ба registrationID-ийн төрөл шалгах oracle нь нэг сервер дээр дахин ажиллуулахад тестүүдийг тогтвортой байлгасан.
PASS, зориуд FAIL, DOWN гурван ажиллуулалт нь зөв үйлдэл, oracle-ийн алдаа болон холболтын алдааг ялган тайлбарлаж, exit code-ийг CI чанарын босго болгон хэрэглэхийг харуулсан.

## Репозиторий ба илгээх

`server.js`, үндсэн болон FAIL collection, `results/` доторх гурван заавал лог, README болон үе шат бүрийн commit-ууд репод хадгалагдсан. Нэмэлт нийтийн API collection, давталтын нотолгоо, npm lockfile ба автоматжуулах скрипт мөн орсон. `.gitignore` нь `.DS_Store`, `.idea/`, `node_modules/`, багшийн `.docx` болон эх `.rar` архивыг хасна.

Одоогоор GitHub remote тохируулаагүй, Teams-д илгээгээгүй. GitHub дээр хоосон **public** репозиторий үүсгээд одоо байгаа commit түүхийг push хийнэ; GitHub вэбээр файл upload хийхгүй:

```sh
git remote add origin https://github.com/B232270013/REPOSITORY_NAME.git
git push -u origin master
```

`REPOSITORY_NAME`-ийг өөрийн үүсгэсэн репозиторийн нэрээр солино. Дараа нь public репозиторийн URL-ийг Teams Assignment-д хавсаргаад **Turn in** дарна. Эдгээр илгээх алхам дуусаагүй тул локал тестүүд амжилттай болсон нь дангаараа лабыг илгээсэн гэсэн үг биш.
