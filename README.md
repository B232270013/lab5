# Лаборатори №5: API систем тест — Postman ба Newman

**Хичээл:** F.CSA313 — Программ хангамжийн чанарын баталгаа ба тест (2026)  
**Оюутан:** Б.Мөнгөншагай  
**Оюутны код:** B232270013

## Зорилго

Хичээлд бүртгүүлэх API-ийн `POST /registrations` үйлдлийг тестэлсэн. Лекц 5-ын таван алхмаар тестийн нөхцөлүүдийг гаргаж, Postman collection үүсгэн Newman-аар ажиллуулсан. Багшийн өгсөн `server.js`-ийг өөрчлөлгүй ашигласан.

## Ашигласан хэрэгсэл

```text
$ node -v
v22.23.3
$ newman -v
6.2.1
```

## Ажиллуулах команд

```sh
npm ci
node server.js
```

Сервер ажиллаж байх үед өөр терминалд:

```sh
npx newman run lab05-collection.json
```

Postman-д `lab05-collection.json` файлыг Import хийж ажиллуулна. Collection-ийн `baseUrl` хувьсагчийн утга нь `http://localhost:3000`.

Энэ компьютерийн түр суулгасан Node.js-ийг ашиглах бол эхлээд:

```sh
export PATH="$(cat /tmp/lab05-tools/node-path.txt):$PATH"
```

## Даалгавар 1. Анхны хүсэлт

[lab05-task1-collection.json](lab05-task1-collection.json) файлд дараах гурван хүсэлт байгаа. Body-г raw JSON хэлбэрээр, `Content-Type: application/json` header-тай өгсөн.

1. `PUT {{baseUrl}}/students/B231234567` — `{"status":"active","coursesTaken":["CS201"]}`
2. `PUT {{baseUrl}}/courses/CS313` — `{"prerequisites":["CS201"]}`
3. `POST {{baseUrl}}/registrations` — `{"studentID":"B231234567","courseID":"CS313"}`

POST хүсэлтийн хариуг хоёр oracle-оор шалгасан:

```javascript
pm.test("HTTP статус 201", function () {
    pm.response.to.have.status(201);
});

pm.test("result = OK", function () {
    pm.expect(pm.response.json().result).to.eql("OK");
});
```

Сервер ажиллаж байх үед энэ collection-ийг ажиллуулах команд:

```sh
npx newman run lab05-task1-collection.json
```

## Даалгавар 2. Тест дизайн

Тест дизайны таван алхмыг дараах байдлаар хийсэн:

1. Тестлэх функцээр `POST /registrations`-ийг сонгосон.
2. Оюутны төлөв, үзсэн хичээл, хичээлийн оршин байх, урьдач нөхцөл болон хүсэлтийн форматыг сонголт болгон авсан.
3. Сонголт бүрийн ангид төлөөлөх утга өгсөн.
4. Амжилттай бүртгэл, дөрвөн төрлийн бизнес алдаа, давхар алдаа болон хязгаарын тохиолдлуудаар 13 спецификаци гаргасан.
5. Спецификаци бүрд өгөгдөл бэлдэх PUT хүсэлт, бүртгүүлэх POST хүсэлт болон хариу шалгах oracle бичсэн.

### Сонголт ба төлөөлөх утга

`coursesTaken` нь оюутны үзсэн хичээлүүд, `prerequisites` нь бүртгүүлэх хичээлийн урьдач нөхцөл юм.

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

Урьдач нөхцөлийн бүх хичээл `coursesTaken` дотор байвал нөхцөл хангана. Байхгүй оюутанд төлөв, үзсэн хичээл оноох боломжгүй. Байхгүй хичээлд урьдач нөхцөл оноох боломжгүй. Урьдач нөхцөлгүй хичээлд «зарим нь дутуу» гэсэн хослол байхгүй.

### Спецификаци

Амжилттай бүртгэлд T01, бизнес алдаа тус бүрд T02–T05, давхар алдаанд T07–T08, хязгаарын тохиолдолд T09–T10-ыг сонгосон. T06, T11–T13 нь нэмэлт нөхцөлүүд. Нийт 13 спецификаци гаргасан.

Хүснэгтийн HTTP статус болон `result` нь `POST /registrations`-ийн хүлээгдэх хариу юм.

| ID | Ангилал | Нөхцөл ба төлөөлөх оролт | HTTP статус | result | Нэмэлт oracle |
|---|---|---|---:|---|---|
| T01 | Амжилттай бүртгэл | `B231234567`: active, coursesTaken=`["CS201"]`; `CS313`: prerequisites=`["CS201"]` | 201 | `OK` | registrationID нь number |
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

T10–T13-ын өгөгдөл бэлдэх үед оюутан `active`, `coursesTaken=["CS201","CS202"]`, хичээл `prerequisites=["CS201","CS202"]` байна.

Бизнес алдаанууд HTTP 200 буцаадаг тул зөвхөн статус шалгах нь хангалтгүй. Тиймээс `result` утгыг давхар шалгасан. T07, T08-аар оюутан байгаа эсэх, идэвхтэй эсэхийг хичээл байгаа эсэхээс өмнө шалгадаг болохыг тогтоосон.

## Даалгавар 3. Collection

[lab05-collection.json](lab05-collection.json) нь 13 нөхцөл, 34 HTTP хүсэлт, 72 assertion-тай. Үүнээс PUT хүсэлтүүдэд 42, POST-ийн статус болон result-д 26, registrationID ба missing-д 4 assertion байна.

Тест бүр шаардлагатай оюутан, хичээлийн өгөгдлөө өөрийн PUT хүсэлтээр бэлддэг. Байхгүй бичлэгийн тестэд `{{$guid}}` ашиглан шинэ ID өгсөн. T07-д хоёр бичлэг хоёул байхгүй байх ёстой тул PUT хүсэлт оруулаагүй.

`registrationID` ажиллуулах бүрд нэмэгддэг учраас яг утгыг нь шалгаагүй, зөвхөн number төрөл эсэхийг шалгасан. T05, T06-д `missing` массив дутуу хичээлүүдтэй таарч байгаа эсэхийг шалгасан.

## Даалгавар 4. Newman ажиллуулалт

PASS, FAIL, DOWN ажиллуулалтыг дараах командаар хийсэн. Энэ командыг өгөхөөс өмнө тусад нь асаасан серверийг зогсооно.

```sh
npm run verify
```

`scripts/run-evidence.sh` нь серверийг асааж PASS, FAIL collection-уудыг ажиллуулаад серверийг зогсоож DOWN тестийг хийдэг. Гаралтыг `tee`-ээр хадгалж, Newman-ийн exit code-ийг `${PIPESTATUS[0]}`-оор авсан.

| Ажиллуулалт | Нотолгоо | Iterations executed / failed | Requests executed / failed | Assertions executed / failed | Newman exit code |
|---|---|---|---|---|---:|
| PASS | [newman-pass.txt](results/newman-pass.txt) | 1 / 0 | 34 / 0 | **72 / 0** | **0** |
| Зориуд FAIL | [newman-fail.txt](results/newman-fail.txt) | 1 / 0 | 34 / 0 | **72 / 1** | **1** |
| Сервер DOWN | [newman-down.txt](results/newman-down.txt) | 1 / 0 | 34 / 34 | **72 / 72** | **1** |

### PASS

Үндсэн collection-ийн 72 assertion бүгд амжилттай, exit code 0 гарсан. Бүтэн гаралт [newman-pass.txt](results/newman-pass.txt)-д байгаа.

### FAIL

[lab05-collection-fail.json](lab05-collection-fail.json)-д T01 POST-ийн статусыг зориуд 201 биш 200 гэж хүлээдэг болгосон. Сервер 201 буцаасан тул нэг assertion унаж, exit code 1 гарсан. Үндсэн collection-ийн хүлээлт 201 хэвээр байгаа. Алдаа гарсан үед exit code 1 буцаж байгаа нь CI шалгалтыг зогсоох үндэс болно.

### DOWN

Серверийг зогсоосны дараа `ECONNREFUSED` гарч, exit code 1 болсон. Энэ нь сервертэй холбогдож чадаагүй интерфейсийн алдаа; FAIL ажиллуулалт нь хариу ирсэн боловч oracle-ийн хүлээлт зөрсөн алдаа юм. DOWN үед HTTP хариу ирээгүй тул 34 хүсэлт болон 72 assertion унасан.

### Давтан ажиллуулалт

Нэг сервер дээр collection-ийг хоёр удаа дараалан ажиллуулсан:

```sh
npx newman run lab05-collection.json --iteration-count 2
```

[newman-repeat.txt](results/newman-repeat.txt)-д 2 iteration, 68 хүсэлт, 144 assertion, 0 failed, exit code 0 гарсан. Энэ нь үндсэн PASS ажиллуулалтаас тусдаа үр дүн юм.

## Даалгавар 5. Нийтийн API

[lab05-public-collection.json](lab05-public-collection.json)-д `GET https://jsonplaceholder.typicode.com/users` хүсэлт оруулсан. Статус 200, хариу массив, эхний хэрэглэгчийн нэр `Leanne Graham` гэсэн гурван oracle бичсэн.

```sh
npx newman run lab05-public-collection.json
```

[newman-public.txt](results/newman-public.txt)-д 1 iteration, 1 хүсэлт, 3 assertion, 0 failed, exit code 0 гарсан. Эдгээр 3 assertion нь үндсэн collection-ийн 72 assertion-д ороогүй. Нийтийн GET API-д өгөгдөл бэлдэх шаардлагагүй байсан ч интернет болон гаднын үйлчилгээний ажиллагаанаас хамаарсан.

## Дүгнэлт

Тест дизайны таван алхмаас тестийн нөхцөл сонгоход хамгийн их бодох шаардлагатай байсан.
Оюутны төлөв, үзсэн хичээл, урьдач нөхцөлийг хослуулж 13 нөхцөл гаргасан.
Байхгүй оюутанд төлөв оноох, байхгүй хичээлд урьдач нөхцөл оноох хослол боломжгүй байв.
Урьдач нөхцөлгүй хичээлд зарим хичээл дутуу гэсэн нөхцөл мөн байхгүй.
Давхар алдааны тестээр сервер оюутны мэдээллийг хичээлийн мэдээллээс өмнө шалгадаг болохыг тогтоосон.
Шалгасан нөхцөлүүдээс серверийн согог илрээгүй.
Тест бүр өгөгдлөө өөрөө бэлддэг тул бусад тестээс хамааралгүй ажилласан.
Нэг сервер дээр хоёр удаа ажиллуулахад бүх шалгалт амжилттай болсон.
Зориуд буруу oracle болон унтарсан серверээр шалгаж, хариуны алдаа ба холболтын алдааг ялгасан.

## Репозиторий

[B232270013/lab5](https://github.com/B232270013/lab5)
