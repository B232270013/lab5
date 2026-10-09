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

## Даалгавар 1: Анхны хүсэлт ба oracle

Тусдаа [lab05-task1-collection.json](lab05-task1-collection.json)-ийг Postman-д Import хийгээд Collection Runner-аар дарааллаар ажиллуулна. Collection variable нь `baseUrl=http://localhost:3000`; гурван хүсэлт бүгд `{{baseUrl}}` ашиглана. Body нь raw JSON, `Content-Type: application/json` байна.

1. `PUT {{baseUrl}}/students/B231234567` — `{"status":"active","coursesTaken":["CS201"]}`
2. `PUT {{baseUrl}}/courses/CS313` — `{"prerequisites":["CS201"]}`
3. `POST {{baseUrl}}/registrations` — `{"studentID":"B231234567","courseID":"CS313"}`

POST хүсэлтийн Tests (Post-response) script нь яг хоёр oracle агуулна:

```javascript
pm.test("HTTP статус 201", function () {
    pm.response.to.have.status(201);
});

pm.test("result = OK", function () {
    pm.expect(pm.response.json().result).to.eql("OK");
});
```

Сервер ажиллаж байх үед Newman-аар шалгах:

```sh
npx newman run lab05-task1-collection.json
```

## Тест дизайны 5 алхам

1. Бие даан тестлэгдэх функц: `POST /registrations`; PUT endpoint-ууд зөвхөн initialization, POST-ийн хариу oracle болно.
2. Сонголтууд: оюутны оршин байх ба төлөв, үзсэн хичээл, хичээлийн оршин байх, урьдач нөхцөл, хүсэлтийн формат.
3. Төлөөлөх утгууд: доорх эквивалент анги тус бүрээс нэг утгыг сонгов.
4. Спецификаци: амжилт, дөрвөн бизнес алдаа, давхар алдаа, хязгаарын тохиолдлуудыг сонгов.
5. Бодит тест: спецификаци бүр тусдаа folder, өөрийн PUT setup, POST хүсэлт, `pm.test` oracle-уудтай байна.

## Даалгавар 2: Тест дизайн — сонголт ба утгын хүснэгт

### Сонголт ба төлөөлөх утга

`studentID` болон `courseID`-гийн хүчинтэй байдал нь тухайн ID-тай бичлэг серверт байгаа эсэхийг илэрхийлнэ; оюутны хувьд төлөвийг мөн ялгана. Үзсэн хичээлүүдийг `coursesTaken`, хичээлийн урьдач нөхцөлийг `prerequisites` талбараар өгнө.

| Сонголт | Эквивалент анги | Төлөөлөх утга / setup | Хамрах спецификаци |
|---|---|---|---|
| studentID-гийн хүчинтэй байдал | Байгаа, идэвхтэй | `B231234567`; `status="active"` | T01 |
| studentID-гийн хүчинтэй байдал | Байгаа, идэвхгүй | `S03`; `status="inactive"` | T03 |
| studentID-гийн хүчинтэй байдал | Байхгүй | `missing_student_{{$guid}}`; оюутны PUT хийхгүй | T02 |
| Оюутны үзсэн хичээлүүд | Урьдач нөхцөл хангана | `coursesTaken=["CS201","CS202"]`, `prerequisites=["CS201","CS202"]` | T03 |
| Оюутны үзсэн хичээлүүд | Урьдач нөхцөл хангахгүй | `coursesTaken=[]` эсвэл `["CS201"]`, `prerequisites=["CS201","CS202"]` | T05, T06 |
| courseID-гийн хүчинтэй байдал | Байгаа | `CS313`; `PUT /courses/CS313`-аар үүсгэнэ | T01 |
| courseID-гийн хүчинтэй байдал | Байхгүй | `missing_course_{{$guid}}`; хичээлийн PUT хийхгүй | T04 |
| Хичээлийн урьдач нөхцөл | Бүгд үзсэн | `prerequisites=["CS201"]`, `coursesTaken=["CS201"]` | T01 |
| Хичээлийн урьдач нөхцөл | Огт үзээгүй | `prerequisites=["CS201","CS202"]`, `coursesTaken=[]` | T05 |
| Хичээлийн урьдач нөхцөл | Зарим нь үзсэн | `prerequisites=["CS201","CS202"]`, `coursesTaken=["CS201"]` | T06 |
| Хичээлийн урьдач нөхцөл | Урьдач нөхцөлгүй | `prerequisites=[]`, `coursesTaken=[]` | T09 |
| Хүсэлтийн талбар | studentID дутуу | POST body: `{"courseID":"C10"}` | T10 |
| Хүсэлтийн талбар | courseID дутуу | POST body: `{"studentID":"S11"}` | T11 |
| Хүсэлтийн талбар | Хоосон ID | POST body: `{"studentID":"","courseID":"C12"}` | T12 |
| Хүсэлтийн формат | Буруу JSON | POST raw body: `{"studentID":` | T13 |

Үзсэн хичээл ба урьдач нөхцөл нь хоорондоо хамааралтай: `prerequisites`-ийн бүх утга `coursesTaken` дотор байвал нөхцөл хангана. Иймээс бүх сонголтын Cartesian үржвэрийг механикаар авахгүй. Байхгүй оюутанд `status`/`coursesTaken`, байхгүй хичээлд `prerequisites` оноох боломжгүй. Урьдач нөхцөлгүй хичээлд «зарим нь үзсэн» буюу «дутуу» анги боломжгүй; хоосон `coursesTaken` ч нөхцөл хангана.

### Спецификаци ба хүлээгдэх үр дүн

Сонголтын стратеги: **happy path 1** (T01), **дөрвөн бизнес алдааны анги тус бүрд 1** (T02–T05), **давхар алдаа 2** (T07–T08), **хязгаарын тохиолдол 2** (T09–T10) — үндсэн **9 спецификаци**. T06 болон T11–T13 нь зарим урьдач нөхцөл дутуу, өөр талбар дутуу, хоосон ID, буруу JSON-ыг нэмж хамарна. Нийт **13 спецификаци**.

Доорх HTTP код ба `result` нь бүгд `POST /registrations`-ийн хүлээгдэх хариу. Ердийн POST body нь `{"studentID":"<оюутны ID>","courseID":"<хичээлийн ID>"}`; өөр body хэрэгтэй мөрүүдэд тусгайлан бичсэн. Байгаа бичлэгүүдийг тухайн спецификацийн PUT setup-аар үүсгэнэ. `missing_student_{{$guid}}`, `missing_course_{{$guid}}` нь шинэ санамсаргүй ID бөгөөд тэдгээрт PUT хийхгүй.

| ID | Ангилал | Нөхцөл ба төлөөлөх оролт | HTTP статус | result | Нэмэлт oracle |
|---|---|---|---:|---|---|
| T01 | Happy path | `B231234567`: active, coursesTaken=`["CS201"]`; `CS313`: prerequisites=`["CS201"]` | 201 | `OK` | registrationID нь number |
| T02 | Алдаа: оюутан байхгүй | `missing_student_{{$guid}}`; `C02`: prerequisites=`["CS201","CS202"]` | 200 | `ERROR_NO_STUDENT` | — |
| T03 | Алдаа: оюутан идэвхгүй | `S03`: inactive, coursesTaken=`["CS201","CS202"]`; `C03`: prerequisites=`["CS201","CS202"]` | 200 | `ERROR_INACTIVE_STUDENT` | — |
| T04 | Алдаа: хичээл байхгүй | `S04`: active, coursesTaken=`["CS201","CS202"]`; `missing_course_{{$guid}}` | 200 | `ERROR_NO_COURSE` | — |
| T05 | Алдаа: урьдач нөхцөл хангахгүй; хоосон coursesTaken | `S05`: active, coursesTaken=`[]`; `C05`: prerequisites=`["CS201","CS202"]` | 200 | `ERROR_PREREQUISITES` | missing=`["CS201","CS202"]` |
| T06 | Нэмэлт: зарим урьдач нөхцөл дутуу | `S06`: active, coursesTaken=`["CS201"]`; `C06`: prerequisites=`["CS201","CS202"]` | 200 | `ERROR_PREREQUISITES` | missing=`["CS202"]` |
| T07 | Давхар алдаа: оюутан, хичээл хоёул байхгүй | `missing_student_{{$guid}}`, `missing_course_{{$guid}}`; хоёр PUT setup хоёул байхгүй | 200 | `ERROR_NO_STUDENT` | Оюутан байгаа эсэхийг түрүүлж шалгана |
| T08 | Давхар алдаа: идэвхгүй оюутан, байхгүй хичээл | `S08`: inactive, coursesTaken=`["CS201","CS202"]`; `missing_course_{{$guid}}` | 200 | `ERROR_INACTIVE_STUDENT` | Оюутны төлөвийг хичээлээс түрүүлж шалгана |
| T09 | Хязгаар: урьдач нөхцөлгүй, хоосон coursesTaken | `S09`: active, coursesTaken=`[]`; `C09`: prerequisites=`[]` | 201 | `OK` | registrationID нь number |
| T10 | Хязгаар: studentID талбар дутуу | `S10`, `C10` setup байгаа; POST body: `{"courseID":"C10"}` | 400 | `ERROR_BAD_REQUEST` | — |
| T11 | Нэмэлт: courseID талбар дутуу | `S11`, `C11` setup байгаа; POST body: `{"studentID":"S11"}` | 400 | `ERROR_BAD_REQUEST` | — |
| T12 | Нэмэлт: хоосон studentID | `S12`, `C12` setup байгаа; POST body: `{"studentID":"","courseID":"C12"}` | 400 | `ERROR_BAD_REQUEST` | — |
| T13 | Нэмэлт: буруу JSON | `S13`, `C13` setup байгаа; POST raw body: `{"studentID":` | 400 | `ERROR_BAD_JSON` | — |

T10–T13-ын setup-д оюутан `active`, `coursesTaken=["CS201","CS202"]`, хичээл `prerequisites=["CS201","CS202"]` байна. Ингэснээр хүсэлтийн талбар/форматын алдааг бусад зөв нөхцөлөөс тусгаарлана.

Энэ API-ийн дөрвөн бизнес алдаа HTTP `200` буцаадаг тул статусын oracle-оос гадна `result`-ийн oracle заавал хэрэгтэй. Талбар дутуу эсвэл ID хоосон үед HTTP `400`, `ERROR_BAD_REQUEST`; JSON parse хийх боломжгүй үед HTTP `400`, `ERROR_BAD_JSON` хүлээнэ.

T07, T08-ын давхар алдааны хүлээлт нь серверийн шалгалтын дараалалтай нийцнэ: JSON parse → шаардлагатай талбар → оюутан байгаа эсэх → active эсэх → хичээл байгаа эсэх → prerequisites. Өмнөх Newman ажиллуулалтын нотолгоо [newman-pass.txt](results/newman-pass.txt)-д хадгалагдсан.

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

GitHub репозиторий: [B232270013/lab5](https://github.com/B232270013/lab5). Commit түүхийг Git push ашиглан хадгална.

```sh
git push -u origin master
```

Teams-д илгээхдээ `https://github.com/B232270013/lab5` линкийг Assignment-д хавсаргаад **Turn in** дарна. Teams-д илгээх алхам хараахан хийгдээгүй.
