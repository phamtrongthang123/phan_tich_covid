Việc thể hiện policy trong data cho phép mình tìm mối liên hệ giữa policy với số case, có thể liên quan số death. Nhưng mới là 1 chiều, đi ngược lại có thể detect anamoly ở mức độ nào đó (không khớp expected).

Trước mắt đọc qua hết coi sao. 

Không thu được mấy =]]] 

Cái SEIR thì có thể extend thêm nhánh in out nhưng mà không có data đó.  https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7139011/ . Nó có ứng dụng lstm lên data sars 2003, nó không public code và không ghi chi tiết nên mình không thể reproduce được. Để dùng lstm thì mình buộc phải tìm hiểu kĩ dùng thế nào trong trường hợp time series vì hiện tại nếu dùng thì ý nghĩa = 0. 

https://www.covidanalytics.io/DELPHI_documentation_pdf này thì extend ra nhiều nhánh. Cái a Hy đang là subset. 

Nói chung cũng toàn extend SEIR không à. 

DELPHI của mit thì lúc học param là đi dùng optimize của scipy, giải ivp cho hệ ode. Mình không rành mấy này.

https://arxiv.org/pdf/2002.12298.pdf SIRU thì cũng chỉ extend ở việc unreported. 



Đi assume prior luôn. Xong dùng mcmc để học. 

https://www.frontiersin.org/articles/10.3389/fmed.2020.00169/full?utm_source=fweb&utm_medium=nblog&utm_campaign=ba-sci-fmed-covid-extended-sir 



Đi modify autoencoder để predict ._. 

https://arxiv.org/ftp/arxiv/papers/2002/2002.07112.pdf



data bazil sida, giống như chết (hoặc khỏi rồi) mới nhập case vậy

